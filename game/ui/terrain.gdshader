shader_type canvas_item;
// Terrain « Émeraude » vu du dessus, calculé au pixel près (aucun quadrillage visible).
// carte : une case par texel, R = type de terrain × 32 / 255 (constantes de GameMap).
// profondeur : R = distance au rivage des cases d'eau (0 sur la terre, 1 = 4 cases et plus).

uniform sampler2D carte : filter_nearest;
uniform sampler2D profondeur : filter_linear;
uniform vec2 taille_carte = vec2(64.0, 64.0);

const int PRAIRIE = 0;
const int FORET = 1;
const int EAU = 2;
const int ROCHE = 3;
const int SABLE = 4;
const int MONTAGNE = 5;
const int MINE_OR = 6;

const vec3 HERBE_SOMBRE = vec3(0.384, 0.682, 0.204);   // 62AE34
const vec3 HERBE_CLAIRE = vec3(0.553, 0.788, 0.290);   // 8DC94A
const vec3 SOUS_BOIS = vec3(0.196, 0.431, 0.165);      // 326E2A
const vec3 SABLE_C = vec3(0.949, 0.839, 0.518);        // F2D684
const vec3 SABLE_GRAIN = vec3(0.847, 0.722, 0.376);    // D8B860
const vec3 EAU_BORD = vec3(0.275, 0.800, 0.816);       // 46CCD0
const vec3 EAU_FOND = vec3(0.118, 0.420, 0.769);       // 1E6BC4
const vec3 GRAVIER = vec3(0.659, 0.635, 0.588);        // A8A296
const vec3 MONT_SOMBRE = vec3(0.369, 0.314, 0.251);    // 5E5040
const vec3 MONT_CLAIR = vec3(0.627, 0.565, 0.478);     // A0907A
const vec3 NEIGE = vec3(0.957, 0.957, 0.941);
const vec3 OR_PEPITE = vec3(1.0, 0.847, 0.290);
const vec3 FEUILLE_SOMBRE = vec3(0.090, 0.310, 0.110);
const vec3 FEUILLE_CLAIRE = vec3(0.420, 0.690, 0.250);
const vec3 PIERRE_SOMBRE = vec3(0.450, 0.430, 0.400);
const vec3 PIERRE_CLAIRE = vec3(0.880, 0.860, 0.820);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

int terrain(vec2 tile) {
	ivec2 t = clamp(ivec2(tile), ivec2(0), ivec2(taille_carte) - 1);
	return int(texelFetch(carte, t, 0).r * 255.0 / 32.0 + 0.5);
}

// Petits points ronds semés au hasard (densité = part des cellules occupées).
float points(vec2 p, float densite, float rayon, float graine) {
	vec2 c = floor(p);
	if (hash(c + graine) > densite) {
		return 0.0;
	}
	vec2 centre = 0.25 + 0.5 * hash2(c + graine);
	float aa = fwidth(p.x);
	return 1.0 - smoothstep(rayon - aa, rayon + aa, length(fract(p) - centre));
}

vec3 herbe(vec2 p) {
	vec3 c = mix(HERBE_SOMBRE, HERBE_CLAIRE, smoothstep(0.32, 0.72, fbm(p * 0.35)));
	c *= 0.95 + 0.1 * noise(p * 5.0);
	// touffes d'herbe et petites fleurs
	c = mix(c, c * 1.16, points(p * 6.0, 0.35, 0.2, 1.0) * 0.8);
	c = mix(c, c * 0.88, points(p * 5.0 + 0.5, 0.25, 0.18, 4.0) * 0.7);
	c = mix(c, vec3(1.0, 0.96, 0.8), points(p * 4.0, 0.03, 0.12, 9.0));
	return c;
}

// Pic de montagne vu de face : base (x, y) en coordonnées de case, hauteur, demi-largeur à la base.
vec4 pic(vec2 v, vec2 base, float hauteur, float demi, float graine, float aa) {
	float apex = base.y - hauteur;
	float t = (v.y - apex) / hauteur;  // 0 au sommet, 1 à la base
	if (t < 0.0 || t > 1.0) {
		return vec4(0.0);
	}
	float dx = v.x - base.x;
	float larg = demi * t * (1.0 + 0.16 * (noise(vec2(v.y * 16.0, graine)) - 0.5));
	float a = 1.0 - smoothstep(larg - aa, larg + aa, abs(dx));
	if (a <= 0.0) {
		return vec4(0.0);
	}
	float arete = dx + 0.06 * (noise(vec2(v.y * 9.0, graine + 3.0)) - 0.5) * t;
	vec3 c = arete < 0.0 ? MONT_CLAIR : MONT_SOMBRE * 1.08;
	c *= 0.9 + 0.14 * noise(v * 24.0 + graine);
	if (arete > 0.0) {
		c *= 0.9 + 0.1 * step(0.5, fract((v.y - dx * 0.7) * 8.0));  // strates sur le versant à l'ombre
	} else {
		c *= 1.04 + 0.06 * (noise(v * 6.0 + graine) - 0.5);  // versant au soleil, à peine grenu
	}
	float limite = 0.42 + 0.12 * (noise(vec2(dx * 28.0, graine)) - 0.5);
	float neige = 1.0 - smoothstep(limite - 0.02, limite + 0.02, t);
	c = mix(c, NEIGE * (arete < 0.0 ? 1.0 : 0.8), neige);
	c *= 1.0 - 0.3 * (1.0 - smoothstep(0.0, 0.025, abs(arete))) * (1.0 - neige * 0.5);  // arête marquée
	c *= 1.0 - 0.35 * smoothstep(larg - 0.05, larg, abs(dx));  // contour sombre
	return vec4(c, a);
}

vec3 sol(int t, vec2 p, vec2 uv) {
	if (t == FORET) {
		return mix(SOUS_BOIS, HERBE_SOMBRE, 0.25 * noise(p * 3.0));
	}
	if (t == SABLE) {
		vec3 c = SABLE_C * (0.95 + 0.07 * noise(p * 2.0));
		c = mix(c, SABLE_GRAIN, points(p * 8.0, 0.4, 0.13, 2.0) * 0.6);
		return mix(c, SABLE_GRAIN * 0.9, smoothstep(0.62, 0.7, noise(p * 1.4 + 3.0)) * 0.25);
	}
	if (t == EAU) {
		float d = texture(profondeur, uv).r;
		vec3 c = mix(EAU_BORD, EAU_FOND, smoothstep(0.08, 0.75, d));
		// reflets qui dérivent lentement, écume le long du rivage
		float vague = noise(vec2(p.x * 2.2 + TIME * 0.25, p.y * 5.5 - TIME * 0.1));
		c = mix(c, vec3(0.85, 0.97, 1.0), smoothstep(0.78, 0.92, vague) * 0.35);
		float ecume = smoothstep(0.16, 0.06, d) * (0.55 + 0.45 * sin(d * 70.0 - TIME * 1.6));
		return mix(c, vec3(0.92, 1.0, 0.98), clamp(ecume, 0.0, 1.0) * 0.55);
	}
	if (t == ROCHE || t == MINE_OR) {
		vec3 c = mix(herbe(p), GRAVIER, 0.55 + 0.3 * noise(p * 1.5));
		c *= 0.92 + 0.12 * noise(p * 10.0);
		if (t == MINE_OR) {
			c = mix(c, vec3(0.70, 0.55, 0.30), 0.35);
			float h = hash(floor(p * 7.0));
			c = mix(c, OR_PEPITE, step(0.86, h) * (0.6 + 0.4 * sin(TIME * 2.0 + h * 30.0)));
		}
		return c;
	}
	if (t == MONTAGNE) {
		// Deux pics par case (un petit derrière, un grand devant) : versant éclairé à gauche, strates à l'ombre, neige dentelée.
		vec2 v = fract(p);
		vec2 g = hash2(floor(p)) - 0.5;
		float aa = fwidth(p.x) * 1.2;
		vec3 rocaille = mix(MONT_SOMBRE, GRAVIER, 0.35 + 0.3 * noise(p * 4.0));
		rocaille *= 0.9 + 0.1 * noise(p * 14.0);
		vec2 b1 = vec2(0.74 + g.x * 0.08, 0.86);
		vec2 b2 = vec2(0.42 + g.y * 0.06, 0.99);
		vec4 fond = pic(v, b1, 0.6 + g.y * 0.08, 0.3, 7.0 + g.x * 9.0, aa);
		vec4 devant = pic(v, b2, 0.9, 0.47, 2.0 + g.y * 13.0, aa);
		// ombre portée des pics vers la droite
		float ombre = max(pic(v - vec2(0.09, -0.02), b2, 0.9, 0.47, 0.0, aa).a, pic(v - vec2(0.07, -0.02), b1, 0.6 + g.y * 0.08, 0.3, 0.0, aa).a);
		vec3 c = rocaille * (1.0 - 0.3 * ombre);
		c = mix(c, fond.rgb * 0.92, fond.a);
		return mix(c, devant.rgb, devant.a);
	}
	return herbe(p);
}

void fragment() {
	vec2 p = UV * taille_carte;  // en cases
	float aa = fwidth(p.x) * 1.5;
	// Bords organiques : on lit le terrain à une position légèrement ondulée.
	vec2 w = vec2(noise(p * 1.3) + 0.5 * noise(p * 2.9), noise(p * 1.3 + vec2(5.2, 1.3)) + 0.5 * noise(p * 2.9 + 7.7)) / 1.5 - 0.5;
	vec2 q = p + w * 0.8;
	int t = terrain(floor(q));
	vec3 col = sol(t, p, q / taille_carte);

	// Arbres (forêt) et rochers (roche, or) : objets ronds en relief, deux par case.
	vec2 cellule = floor(p * 2.0);
	float ombre = 0.0;
	for (int oy = -1; oy <= 1; oy++) {
		for (int ox = -1; ox <= 1; ox++) {
			vec2 c = cellule + vec2(float(ox), float(oy));
			vec2 centre = (c + 0.2 + 0.6 * hash2(c)) / 2.0;
			int tc = terrain(floor(centre));
			float r = 0.0;
			if (tc == FORET && hash(c + 3.1) < 0.92) {
				r = 0.3 + 0.13 * hash(c + 5.7);
			} else if ((tc == ROCHE || tc == MINE_OR) && hash(c + 7.3) > 0.45) {
				r = 0.14 + 0.1 * hash(c + 9.1);
			}
			if (r > 0.0) {
				float d = length(p - centre - vec2(0.09, 0.13));
				ombre = max(ombre, 1.0 - smoothstep(r - aa, r + aa * 2.0, d));
			}
		}
	}
	col *= 1.0 - 0.38 * ombre;
	for (int oy = -1; oy <= 1; oy++) {
		for (int ox = -1; ox <= 1; ox++) {
			vec2 c = cellule + vec2(float(ox), float(oy));
			vec2 centre = (c + 0.2 + 0.6 * hash2(c)) / 2.0;
			int tc = terrain(floor(centre));
			if (tc == FORET && hash(c + 3.1) < 0.92) {
				float r = 0.3 + 0.13 * hash(c + 5.7);
				vec2 v = (p - centre) / r;
				float ang = atan(v.y, v.x);
				bool sapin = hash(c + 21.0) < 0.3;
				// silhouette : feuillu lobé, ou conifère étoilé
				float bord = sapin ? 0.8 + 0.2 * abs(cos(ang * 4.0 + hash(c) * 6.0)) : 1.0 + 0.05 * sin(ang * 7.0 + hash(c) * 6.0) + 0.1 * (noise(vec2(ang * 2.2 + 4.0, hash(c) * 40.0)) - 0.5);
				float d = length(v) / bord;
				float masque = 1.0 - smoothstep(1.0 - aa / r, 1.0, d);
				if (masque > 0.0) {
					float lumiere = clamp(1.05 - length(v - vec2(-0.35, -0.45)) * 0.75, 0.0, 1.0);
					vec3 teinte;
					if (sapin) {
						// étages de branches concentriques, cime claire
						teinte = mix(FEUILLE_SOMBRE * vec3(0.8, 0.95, 1.05), FEUILLE_CLAIRE * vec3(0.7, 0.9, 0.85), lumiere * 0.8);
						teinte *= 0.86 + 0.14 * step(0.45, fract(d * 3.2));
						teinte = mix(teinte, FEUILLE_CLAIRE, (1.0 - smoothstep(0.0, 0.2, d)) * 0.6);
					} else {
						teinte = mix(FEUILLE_SOMBRE, FEUILLE_CLAIRE, lumiere);
						// grappes de feuilles : petites boules plus claires vers la lumière
						float grappe = points(v * 2.6 + hash(c) * 4.0, 0.8, 0.32, 13.0);
						teinte = mix(teinte, teinte * 1.18, grappe * lumiere);
						teinte *= 0.9 + 0.1 * hash(c + 11.0) + 0.12 * (noise(p * 16.0) - 0.5);
					}
					teinte = mix(teinte, FEUILLE_SOMBRE * 0.7, smoothstep(0.8, 1.0, d) * 0.7);
					col = mix(col, teinte, masque);
				}
			} else if ((tc == ROCHE || tc == MINE_OR) && hash(c + 7.3) > 0.45) {
				float r = 0.14 + 0.1 * hash(c + 9.1);
				vec2 v = (p - centre) / r;
				v.y *= 1.2;
				float ang = atan(v.y, v.x);
				// bloc anguleux : rayon irrégulier selon l'angle, facettes
				float bord = 1.0 + 0.2 * (noise(vec2(ang * 1.6 + 10.0, hash(c) * 50.0)) - 0.5) * 2.0;
				float d = length(v) / bord;
				float masque = 1.0 - smoothstep(1.0 - aa / r, 1.0, d);
				if (masque > 0.0) {
					float facette = floor((ang + 3.1416) / 1.0471 + hash(c) * 6.0);
					float lumiere = clamp(1.0 - length(v - vec2(-0.3, -0.5)) * 0.7, 0.0, 1.0);
					lumiere = mix(lumiere, 0.35 + 0.5 * hash(vec2(facette, c.x)), 0.35);
					vec3 teinte = mix(PIERRE_SOMBRE, PIERRE_CLAIRE, lumiere);
					// fissure et mousse
					float fissure = 1.0 - smoothstep(0.0, 0.06, abs(dot(v, normalize(hash2(c + 2.0) - 0.5))));
					teinte *= 1.0 - 0.35 * fissure * step(d, 0.75);
					teinte = mix(teinte, FEUILLE_CLAIRE * 0.8, step(0.82, noise(v * 5.0 + c)) * step(v.y, -0.2) * 0.6);
					if (tc == MINE_OR) {
						// filons d'or qui scintillent
						float filon = smoothstep(0.62, 0.7, noise(v * 3.5 + c * 1.7));
						float eclat = 0.75 + 0.25 * sin(TIME * 3.0 + hash(c) * 20.0);
						teinte = mix(teinte, OR_PEPITE * eclat, filon);
						float etoile = (1.0 - smoothstep(0.0, 0.05, abs(v.x - 0.2))) + (1.0 - smoothstep(0.0, 0.05, abs(v.y + 0.25)));
						etoile *= (1.0 - smoothstep(0.0, 0.35, length(v - vec2(0.2, -0.25)))) * max(0.0, sin(TIME * 2.0 + hash(c) * 30.0));
						teinte = mix(teinte, vec3(1.0, 1.0, 0.85), clamp(etoile, 0.0, 1.0));
					}
					teinte = mix(teinte, PIERRE_SOMBRE * 0.6, smoothstep(0.78, 1.0, d) * 0.75);
					col = mix(col, teinte, masque);
				}
			}
		}
	}
	COLOR = vec4(col, 1.0);
}
