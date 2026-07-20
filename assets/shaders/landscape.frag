// =============================================================================
// landscape.frag — Paisagem procedural 100% matemática (sem sampler2D/imagens)
// -----------------------------------------------------------------------------
// Motor: Fractal Brownian Motion (FBM) sobre value-noise 2D + heightmap por
// coluna para até 3 camadas de terreno, iluminação Lambert + realce
// Blinn-Phong aproximado nas cristas, "god-rays" 2D baratos em vez de
// raymarching volumétrico 3D (mantém 60fps em Android mid-range), e haze
// atmosférico por profundidade (camadas de trás mais claras/dessaturadas).
//
// COMPATIBILIDADE: escrito no dialeto GLSL que o compilador de shaders do
// Flutter (impellerc) aceita — usa o header oficial flutter/runtime_effect.glsl
// e FlutterFragCoord() em vez de gl_FragCoord.
//
// ORDEM DOS UNIFORMS: os valores são enviados do Dart via shader.setFloat(i, v)
// em ORDEM SEQUENCIAL DE DECLARAÇÃO (cada vec2/vec3 consome 2/3 slots
// consecutivos). NÃO reordene as declarações abaixo sem atualizar o Dart.
// =============================================================================

#include <flutter/runtime_effect.glsl>

// ---- 1. Resolução do canvas (em pixels lógicos) ----------------------------
uniform vec2 uSize;

// ---- 2. Tempo (segundos) — anima só god-rays/estrelas, terreno é estático --
uniform float uTime;

// ---- 3. Seed do "dia" — desloca o domínio do ruído (varia o terreno) -------
uniform float uSeed;

// ---- 4. Tipo de cenário: 0 = montanhas | 1 = colinas c/ vegetação | 2 = dunas/formas orgânicas
uniform float uScenario;

// ---- 5. Direção do sol/lua no plano da cena (não precisa ser normalizado) --
uniform vec2 uSunDir;

// ---- 6/7. Gradiente do céu ---------------------------------------------
uniform vec3 uSkyTop;
uniform vec3 uSkyBottom;

// ---- 8/9. Paleta do terreno ----------------------------------------------
uniform vec3 uGrassColor; // usado em colinas/vegetação
uniform vec3 uRockColor;  // usado em montanhas/rochas

// ---- 10. Cor do haze atmosférico (para onde as camadas distantes tendem) --
uniform vec3 uHazeColor;

// ---- 11. Cor do sol/lua e seu brilho -------------------------------------
uniform vec3 uSunColor;

// ---- 12. 1.0 = cena noturna (lua + estrelas) | 0.0 = cena diurna (sol) ----
uniform float uIsNight;

out vec4 fragColor;

// =============================================================================
// SEÇÃO: NOISE / FBM
// (Módulo independente — pode ser reaproveitado por qualquer elemento novo)
// =============================================================================

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Value noise 2D suavizado (interpolação quíntica).
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

const int FBM_OCTAVES = 5;

// Fractal Brownian Motion: soma de oitavas de valueNoise com amplitude/freq
// decrescente/crescente — gera o relevo orgânico do terreno.
float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxAmp = 0.0;
    for (int i = 0; i < FBM_OCTAVES; i++) {
        total += valueNoise(p * frequency) * amplitude;
        maxAmp += amplitude;
        amplitude *= 0.5;
        frequency *= 2.02; // fator não-inteiro evita repetição visível
    }
    return total / maxAmp; // normalizado [0,1]
}

// FBM "ridged" — dobra o ruído sobre si mesmo, produz cristas afiadas
// (bom para montanhas).
float ridgedFbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxAmp = 0.0;
    for (int i = 0; i < FBM_OCTAVES; i++) {
        float n = 1.0 - abs(valueNoise(p * frequency) * 2.0 - 1.0);
        n = n * n; // acentua as cristas
        total += n * amplitude;
        maxAmp += amplitude;
        amplitude *= 0.5;
        frequency *= 2.05;
    }
    return total / maxAmp;
}

// FBM "domain-warped" — distorce as próprias coordenadas de entrada com
// outro fbm antes de amostrar, produzindo formas fluidas/orgânicas (dunas).
float warpedFbm(vec2 p) {
    vec2 warp = vec2(fbm(p + vec2(1.7, 9.2)), fbm(p + vec2(8.3, 2.8)));
    return fbm(p + warp * 1.4);
}

// =============================================================================
// SEÇÃO: TERRENO (heightmap por coluna)
// Módulo independente: para adicionar um novo tipo de cenário, basta criar
// uma nova função `terrainHeightX` e um novo `else if (uScenario ...)` abaixo.
// =============================================================================

// Retorna a altura do terreno (0..1, relativo à altura do canvas) para uma
// dada coluna `x` (em coordenadas de ruído já escaladas) e uma `layerSeed`
// que diferencia as camadas (frente/meio/fundo).
float terrainHeight(float x, float layerSeed, float scenario) {
    vec2 p = vec2(x, layerSeed * 31.7 + uSeed * 7.13);

    if (scenario < 0.5) {
        // 0: MONTANHAS — cristas afiadas, alta amplitude.
        float h = ridgedFbm(p * 1.6);
        return h;
    } else if (scenario < 1.5) {
        // 1: COLINAS COM VEGETAÇÃO — ondulações suaves, baixa amplitude.
        float h = fbm(p * 1.1);
        return h * 0.55 + 0.10;
    } else {
        // 2: FORMAS ORGÂNICAS (dunas) — fbm com domain warp, curvas fluidas.
        float h = warpedFbm(p * 0.9);
        return h * 0.7;
    }
}

// Textura de "copas de árvores" — pontinhos de alta frequência usados só na
// cor da camada de vegetação (cenário 1), nunca na geometria.
float canopySpeckle(vec2 p) {
    float n = valueNoise(p * 18.0);
    return smoothstep(0.55, 0.85, n);
}

// =============================================================================
// SEÇÃO: ILUMINAÇÃO (Lambert + realce Blinn-Phong aproximado)
// =============================================================================

// Deriva a normal 2D do heightmap por diferença central e aplica
// iluminação direcional Lambertiana + um brilho especular suave nas
// cristas voltadas para o sol (aproximação barata de Blinn-Phong, sem
// precisar de normais 3D reais).
vec3 shadeTerrain(vec3 baseColor, float x, float layerSeed, float scenario, vec2 sunDir, vec3 sunColor) {
    float eps = 0.01;
    float hL = terrainHeight(x - eps, layerSeed, scenario);
    float hR = terrainHeight(x + eps, layerSeed, scenario);
    vec2 normal = normalize(vec2(hL - hR, 2.0 * eps));

    vec2 lightDir = normalize(sunDir);
    float lambert = clamp(dot(normal, lightDir), 0.0, 1.0);

    // Termo especular aproximado: quanto mais a normal "olha" para o sol,
    // mais forte o realce — simula Blinn-Phong sem vetor de câmera 3D real
    // (câmera assumida "de frente", vetor de visão = (0,1)).
    vec2 viewDir = vec2(0.0, 1.0);
    vec2 halfVec = normalize(lightDir + viewDir);
    float spec = pow(clamp(dot(normal, halfVec), 0.0, 1.0), 24.0) * 0.35;

    float ambient = 0.35; // luz ambiente mínima para nada ficar 100% preto
    vec3 lit = baseColor * (ambient + lambert * 0.65) + sunColor * spec;
    return lit;
}

// =============================================================================
// SEÇÃO: CÉU, ASTRO (SOL/LUA) E GOD-RAYS 2D
// =============================================================================

vec3 paintSky(vec2 uv) {
    return mix(uSkyBottom, uSkyTop, pow(uv.y, 0.85));
}

// Disco do sol/lua com halo suave — 100% procedural (círculos + blur via
// smoothstep, sem sampler2D).
vec3 paintSunOrMoon(vec2 uv, vec2 sunPos, vec3 baseSky) {
    float d = distance(uv, sunPos);
    vec3 col = baseSky;

    // Halo externo (glow)
    float halo = smoothstep(0.22, 0.0, d);
    col += uSunColor * halo * 0.5;

    // Disco nítido
    float disc = smoothstep(0.052, 0.045, d);
    col = mix(col, uSunColor, disc);

    if (uIsNight > 0.5) {
        // Estrelas: pontos esparsos via hash, só na metade superior do céu.
        vec2 starGrid = uv * vec2(uSize.x, uSize.y) / 26.0;
        vec2 cell = floor(starGrid);
        float starHash = hash21(cell + uSeed);
        float starTwinkle = 0.55 + 0.45 * sin(uTime * 2.3 + starHash * 40.0);
        if (starHash > 0.965 && uv.y < 0.62) {
            vec2 cellUv = fract(starGrid) - 0.5;
            float starDot = smoothstep(0.10, 0.0, length(cellUv));
            col += vec3(1.0) * starDot * starTwinkle * 0.8;
        }
    }
    return col;
}

// God-rays 2D baratos: raios radiais a partir da posição do sol, modulados
// por ruído angular. Custo O(1) por pixel — sem raymarching 3D.
vec3 applyGodRays(vec3 color, vec2 uv, vec2 sunPos) {
    if (uIsNight > 0.5) return color; // só de dia
    vec2 toPixel = uv - sunPos;
    float ang = atan(toPixel.y, toPixel.x);
    float dist = length(toPixel);

    float rays = sin(ang * 10.0 + hash21(vec2(uSeed, 3.1)) * 6.28) * 0.5 + 0.5;
    rays = pow(rays, 3.0);
    float falloff = smoothstep(0.9, 0.05, dist);
    float intensity = rays * falloff * 0.18;

    return color + uSunColor * intensity;
}

// =============================================================================
// SEÇÃO: HAZE ATMOSFÉRICO DE PROFUNDIDADE
// =============================================================================

// Mistura a cor de uma camada com a cor de neblina conforme sua distância
// (0 = camada da frente, 1 = camada mais ao fundo) e a altura na tela
// (perto do "horizonte" da própria camada = mais neblina).
vec3 applyDepthHaze(vec3 color, float layerDepth, float verticalFade) {
    float haze = layerDepth * 0.55 + verticalFade * 0.25;
    haze = clamp(haze, 0.0, 0.85);
    return mix(color, uHazeColor, haze);
}

// =============================================================================
// MAIN — composição final: céu -> astro -> god-rays -> 3 camadas de terreno
// =============================================================================

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;         // 0..1, y cresce para baixo
    vec2 uvUp = vec2(uv.x, 1.0 - uv.y);  // y cresce para cima (mais intuitivo p/ céu)

    vec2 sunPos = vec2(0.5 + uSunDir.x * 0.4, 0.65 + uSunDir.y * 0.3);

    // 1) Céu
    vec3 color = paintSky(uvUp);

    // 2) Sol/Lua + estrelas
    color = paintSunOrMoon(uvUp, sunPos, color);

    // 3) God-rays (barato, 2D)
    color = applyGodRays(color, uvUp, sunPos);

    // 4) Camadas de terreno (fundo -> frente), cada uma com sua própria
    //    altura de base, cor, iluminação e haze de profundidade.
    //    layerDepth: 1.0 = mais distante (mais haze), 0.0 = mais perto.
    vec3 terrainBaseColor = uScenario < 0.5 ? uRockColor : uGrassColor;

    // --- Camada de fundo ---
    {
        float baseline = 0.42;
        float amp = 0.16;
        float h = terrainHeight(uv.x * 2.3, 1.0, uScenario);
        float surfaceY = 1.0 - (baseline + h * amp);
        if (uvUp.y < surfaceY) {
            vec3 lit = shadeTerrain(terrainBaseColor * 0.85, uv.x * 2.3, 1.0, uScenario, uSunDir, uSunColor);
            lit = applyDepthHaze(lit, 0.85, 1.0 - uvUp.y);
            color = lit;
        }
    }

    // --- Camada do meio ---
    {
        float baseline = 0.26;
        float amp = 0.20;
        float h = terrainHeight(uv.x * 2.3, 2.0, uScenario);
        float surfaceY = 1.0 - (baseline + h * amp);
        if (uvUp.y < surfaceY) {
            vec3 layerColor = terrainBaseColor * 0.95;
            if (uScenario > 0.5 && uScenario < 1.5) {
                // Vegetação: mescla textura de copas na cor da camada.
                float speck = canopySpeckle(vec2(uv.x * 40.0, 2.0));
                layerColor = mix(layerColor, uGrassColor * 0.75, speck * 0.4);
            }
            vec3 lit = shadeTerrain(layerColor, uv.x * 2.3, 2.0, uScenario, uSunDir, uSunColor);
            lit = applyDepthHaze(lit, 0.45, 1.0 - uvUp.y);
            color = lit;
        }
    }

    // --- Camada da frente (mais escura, sem haze — está "perto da câmera") ---
    {
        float baseline = 0.06;
        float amp = 0.22;
        float h = terrainHeight(uv.x * 2.3, 3.0, uScenario);
        float surfaceY = 1.0 - (baseline + h * amp);
        if (uvUp.y < surfaceY) {
            vec3 layerColor = terrainBaseColor * 1.05;
            if (uScenario > 0.5 && uScenario < 1.5) {
                float speck = canopySpeckle(vec2(uv.x * 55.0 + 12.0, 3.0));
                layerColor = mix(layerColor, uGrassColor * 0.7, speck * 0.45);
            }
            vec3 lit = shadeTerrain(layerColor, uv.x * 2.3, 3.0, uScenario, uSunDir, uSunColor);
            lit = applyDepthHaze(lit, 0.08, 1.0 - uvUp.y);
            color = lit;
        }
    }

    fragColor = vec4(color, 1.0);
}
