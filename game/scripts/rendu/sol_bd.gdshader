// Sol de la carte, style « BD néo ligne claire en semi-perspective ».
// Une case = 1 unité dans les coordonnées « p ». Les masques (1 texel par case, filtrage linéaire)
// donnent des bords arrondis ; le bruit les rend organiques ; l'encre suit les bords à épaisseur constante à l'écran.
// Axes d'enrichissement (11/11/2026) : uniformes ax_* (CarteBD.AXES). Tous à false = rendu d'origine à l'identique.
shader_type canvas_item;

uniform vec2 taille_carte = vec2(64.0, 64.0);
uniform sampler2D masque_a : filter_linear, repeat_disable;   // R eau, G forêt, B roche, A sable
uniform sampler2D masque_b : filter_linear, repeat_disable;   // R montagne, G or, B route, A pont
uniform sampler2D masque_c : filter_linear, repeat_disable;   // R profondeur d'eau (0 bord → 1 large)
uniform sampler2D bruit : filter_linear, repeat_enable;
uniform sampler2D tex_herbe : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_sable : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_roche : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_eau : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_falaise : filter_linear_mipmap, repeat_enable;

uniform float hauteur_falaise = 0.55;   // en cases
uniform float decalage_eau = 0.22;      // la surface de l'eau est plus basse que la berge (en cases)
uniform float epaisseur_encre = 1.25;   // en pixels écran
uniform float temps_eau = 0.0;          // animation douce des rides (secondes)

uniform bool ax_contours = false;
uniform bool ax_eau = false;
uniform bool ax_geographie = false;
uniform bool ax_relief = false;
uniform bool ax_matieres = false;
uniform bool ax_vegetation = false;
uniform bool ax_vie = false;
uniform bool ax_lod = false;
uniform bool ax_journee = false;
uniform bool ax_travail = false;
uniform vec2 dir_ombre = vec2(0.45, 0.35);   // axe journée : direction des ombres (en cases), tourne avec le soleil
uniform sampler2D usure : filter_linear, repeat_disable;   // axe travail : R = herbe usée (2 texels par case)
const vec3 TERRE_BATTUE = vec3(0.835, 0.765, 0.565);   // #D5C390
// 3e lot : sables, eaux, massifs, prairies, forêts (visiteurs : main.gd)
uniform bool ax_sables = false;
uniform bool ax_eaux = false;
uniform bool ax_massifs = false;
uniform bool ax_prairies = false;
uniform bool ax_forets = false;
uniform bool ax_visiteurs = false;
uniform vec2 camp_centre = vec2(-100.0);

const vec3 ENCRE = vec3(0.078, 0.125, 0.169);          // #14202B
const vec3 HERBE = vec3(0.549, 0.761, 0.353);          // #8CC25A
const vec3 HERBE_SOMBRE = vec3(0.498, 0.714, 0.310);   // #7FB64F
const vec3 HERBE_CLAIRE = vec3(0.616, 0.796, 0.400);   // #9DCB66
const vec3 HERBE_HUMIDE = vec3(0.420, 0.659, 0.290);   // #6BA84A
const vec3 HERBE_SECHE = vec3(0.722, 0.776, 0.416);    // #B8C66A
const vec3 LISIERE = vec3(0.431, 0.647, 0.282);        // #6EA548
const vec3 SOL_FORET = vec3(0.369, 0.569, 0.271);      // #5E9145
const vec3 SABLE = vec3(0.914, 0.808, 0.541);          // #E9CE8A
const vec3 SABLE_CLAIR = vec3(0.953, 0.867, 0.643);    // #F3DDA4
const vec3 SABLE_MOUILLE = vec3(0.808, 0.690, 0.455);  // #CEB074
const vec3 ROCHE = vec3(0.741, 0.722, 0.667);          // #BDB8AA
const vec3 ROCHE_SOMBRE = vec3(0.655, 0.631, 0.576);   // #A7A193
const vec3 BERGE = vec3(0.557, 0.478, 0.353);          // #8E7A5A
const vec3 EAU_HAUT_FOND = vec3(0.486, 0.800, 0.902);  // #7CCCE6
const vec3 EAU_TURQUOISE = vec3(0.553, 0.871, 0.886);  // #8DDEE2
const vec3 EAU = vec3(0.275, 0.663, 0.839);            // #46A9D6
const vec3 EAU_2 = vec3(0.180, 0.549, 0.769);          // #2E8CC4
const vec3 EAU_3 = vec3(0.133, 0.447, 0.659);          // #2272A8
const vec3 NENUPHAR = vec3(0.420, 0.690, 0.318);       // #6BB051
const vec3 CHEMIN = vec3(0.902, 0.796, 0.580);         // #E6CB94
const vec3 CHEMIN_BORD = vec3(0.788, 0.643, 0.408);    // #C9A468
const vec3 PLANCHE = vec3(0.722, 0.525, 0.306);        // #B8864E
const vec3 FALAISE_HAUT = vec3(0.678, 0.631, 0.565);   // #ADA190
const vec3 FALAISE_BAS = vec3(0.373, 0.341, 0.294);    // #5F574B
const vec3 MONT_DESSUS = vec3(0.639, 0.612, 0.549);    // #A39C8C

float n1(vec2 q) { return texture(bruit, q).r; }
float h21(vec2 q) { return fract(sin(dot(q, vec2(127.1, 311.7))) * 43758.5453); }

// Valeur lissée d'un masque + bruit ; 0.5 = bord.
float champ(sampler2D m, int canal, vec2 p, float amp) {
	vec4 v = texture(m, p / taille_carte);
	float x = canal == 0 ? v.r : canal == 1 ? v.g : canal == 2 ? v.b : v.a;
	float n = (n1(p * 0.045) - 0.5) * 0.9 + (n1(p * 0.19 + 0.37) - 0.5) * 0.35;
	return x + n * amp;
}
float brut(sampler2D m, int canal, vec2 p) {
	vec4 v = texture(m, p / taille_carte);
	return canal == 0 ? v.r : canal == 1 ? v.g : canal == 2 ? v.b : v.a;
}
// Présence d'un terrain autour de p (rayon r en cases) : moyenne de 9 lectures.
float autour(sampler2D m, int canal, vec2 p, float r) {
	float s = 0.0;
	for (int i = -1; i <= 1; i++) for (int j = -1; j <= 1; j++) s += brut(m, canal, p + vec2(float(i), float(j)) * r);
	return s / 9.0;
}
float dedans(float v) { float w = max(fwidth(v), 1e-4); return smoothstep(0.5 - w, 0.5 + w, v); }
float encre(float v, float k) { float w = max(fwidth(v), 1e-4); return 1.0 - smoothstep(k * 0.5, k * 0.5 + 1.0, abs(v - 0.5) / w); }
vec4 detail(sampler2D t, vec2 p) { return texture(t, p / 4.0); }
vec3 sur(vec3 c, vec4 d) { return mix(c, d.rgb, d.a); }

void fragment() {
	vec2 p = UV * taille_carte;
	float k = epaisseur_encre;
	float ppc = 1.0 / max(fwidth(p.x), 1e-4);              // pixels écran par case
	float pres = smoothstep(26.0, 90.0, ppc);              // 0 de loin → 1 de près
	float A_c = ax_contours ? 1.0 : 0.0;
	float A_g = ax_geographie ? 1.0 : 0.0;
	float A_r = ax_relief ? 1.0 : 0.0;
	float A_m = ax_matieres ? 1.0 : 0.0;
	float A_e = ax_eau ? 1.0 : 0.0;
	// Contours : trait plein pour les dénivellations (berges, falaises), trait fin et partiel pour les transitions à plat
	float k_plat = ax_contours ? k * mix(0.7, 1.0, pres) : k;
	float a_plat = ax_contours ? mix(0.72, 1.0, pres) : 1.0;
	float k_relief = ax_contours ? k * mix(1.0, 1.35, pres) : k;
	// Bord « touffu » des transitions à plat : bruit fin qui fait déborder l'herbe
	float touffe = A_c * (n1(p * 0.22 + 4.2) - 0.5) * 0.14;
	// LOD : densité des micro-détails selon le zoom
	float lod = ax_lod ? mix(0.55, 1.0, pres) : 1.0;
	float lod_roche = ax_lod ? mix(0.75, 1.0, pres) : 1.0;
	// Proximité de l'eau (berges, plages, herbe humide)
	float pres_eau = (ax_geographie || ax_matieres || ax_sables) ? max(autour(masque_a, 0, p, 0.9), autour(masque_a, 0, p, 1.8) * 0.7) : 0.0;

	// ---------- prairie : trois tons en taches, liseré discret, détails dessinés
	float t1 = n1(p * 0.06 + 3.1); float t2 = n1(p * 0.06 + 7.7);
	vec3 c = HERBE;
	float pa = dedans(t1 + 0.12); c = mix(c, HERBE_SOMBRE, pa);
	float pb = dedans(t2 - 0.16); c = mix(c, HERBE_CLAIRE, pb);
	c = mix(c, ENCRE, 0.18 * (1.0 - 0.5 * A_c) * max(encre(t1 + 0.12, 0.8), encre(t2 - 0.16, 0.8)));
	if (ax_matieres) {
		// grandes zones sèches et humides, à l'échelle de la carte
		float sec = smoothstep(0.6, 0.75, n1(p * 0.011 + 21.0));
		c = mix(c, HERBE_SECHE, sec * 0.25);
		c = mix(c, HERBE_HUMIDE, smoothstep(0.08, 0.45, pres_eau) * 0.4);
	}
	float f_brut = texture(masque_a, p / taille_carte).g;
	c = mix(c, LISIERE, smoothstep(0.08, 0.45, f_brut) * 0.8);
	vec4 dh = detail(tex_herbe, p);
	vec4 dh2 = detail(tex_herbe, p * 0.77 + vec2(1.3, 2.1));
	vec4 dsel = n1(p * 0.11) > 0.5 ? dh : dh2;
	float pre_fleurs = ax_matieres ? smoothstep(0.52, 0.64, n1(p * 0.025 + 13.0)) : 0.0;
	dsel.a *= lod * (ax_matieres ? mix(0.65, 1.0, pre_fleurs) : 1.0);
	c = sur(c, dsel);
	if (ax_matieres) {
		// champs de fleurs : petits points regroupés (blanc, jaune, mauve), plus fournis de près
		vec2 g = p * 3.2;
		vec2 id = floor(g);
		float r = h21(id);
		vec2 ctr = id + 0.5 + (vec2(h21(id + 7.1), h21(id + 3.3)) - 0.5) * 0.6;
		float d = length(g - ctr);
		float fl = (1.0 - smoothstep(0.11, 0.16, d)) * step(1.0 - pre_fleurs * 0.45, r) * smoothstep(18.0, 40.0, ppc);
		float r2 = h21(id + 12.0);
		vec3 cf = r2 < 0.4 ? vec3(0.97, 0.96, 0.9) : (r2 < 0.78 ? vec3(0.99, 0.83, 0.3) : vec3(0.8, 0.64, 0.92));
		c = mix(c, cf, fl);
		c = mix(c, ENCRE, (smoothstep(0.1, 0.15, d) - smoothstep(0.16, 0.2, d)) * step(1.0 - pre_fleurs * 0.45, r) * 0.5 * smoothstep(40.0, 80.0, ppc));
	}

	// ---------- prairies : fauchée autour du camp, trèfles et pâquerettes par zones
	if (ax_prairies) {
		float dc = length(p - camp_centre) + (n1(p * 0.3 + 9.0) - 0.5) * 1.4;
		float fauche = 1.0 - smoothstep(4.0, 6.0, dc);
		float bande = smoothstep(0.45, 0.55, abs(fract((p.x + p.y) * 0.7) - 0.5) * 2.0);
		c = mix(c, mix(HERBE_CLAIRE, HERBE * 0.97, bande), fauche * 0.6);
		float zone_t = smoothstep(0.58, 0.66, n1(p * 0.05 + 31.0)) * (1.0 - fauche) * smoothstep(30.0, 60.0, ppc);
		vec2 g = p * 5.0; vec2 id = floor(g);
		vec2 o = g - id - 0.5 - (vec2(h21(id + 2.0), h21(id + 5.0)) - 0.5) * 0.4;
		float tr = 1.0;
		for (int i = 0; i < 3; i++) {
			float a = 6.283 * float(i) / 3.0 + h21(id) * 6.0;
			tr = min(tr, length(o - 0.085 * vec2(cos(a), sin(a))));
		}
		c = mix(c, HERBE_HUMIDE * 0.9, (1.0 - smoothstep(0.065, 0.09, tr)) * step(0.5, h21(id + 8.0)) * zone_t);
		float zone_p = smoothstep(0.6, 0.68, n1(p * 0.04 + 47.0)) * (1.0 - fauche);
		vec2 g2 = p * 3.6; vec2 id2 = floor(g2);
		vec2 o2 = g2 - id2 - 0.5 - (vec2(h21(id2 + 1.0), h21(id2 + 4.0)) - 0.5) * 0.5;
		float sp = step(0.6, h21(id2 + 3.0)) * zone_p * smoothstep(36.0, 66.0, ppc);
		float dp = length(o2);
		c = mix(c, vec3(0.98, 0.97, 0.93), (1.0 - smoothstep(0.075, 0.1, dp)) * sp);
		c = mix(c, vec3(1.0, 0.8, 0.25), (1.0 - smoothstep(0.03, 0.045, dp)) * sp);
	}

	// ---------- chemins de traverse : l'herbe s'use là où les collaborateurs passent souvent
	if (ax_travail) {
		float us = texture(usure, p / taille_carte).r;
		float bord = (n1(p * 0.35 + 6.0) - 0.5) * 0.25;
		float u1 = smoothstep(0.18, 0.4, us + bord);
		float u2 = smoothstep(0.45, 0.75, us + bord);
		c = mix(c, mix(HERBE_SECHE, c, 0.35), u1 * 0.8);
		c = mix(c, TERRE_BATTUE, u2 * 0.9);
	}

	// ---------- sable
	float vs = champ(masque_a, 3, p, 0.5) + touffe;
	vec3 cs = mix(SABLE, SABLE_CLAIR, smoothstep(0.75, 0.95, vs));
	vec4 dsa = detail(tex_sable, p); dsa.a *= lod;
	cs = sur(cs, dsa);
	if (ax_matieres) {
		// rides du vent
		float ride = sin(p.y * 7.0 + p.x * 1.3 + n1(p * 0.3) * 6.0);
		cs = mix(cs, SABLE_MOUILLE, smoothstep(0.93, 0.99, ride) * 0.18 * pres);
	}
	if (ax_sables) {
		// dunes : longues crêtes douces (vent du nord-ouest), versant sous le vent ombré, dans les grandes étendues
		float large = smoothstep(0.55, 0.85, autour(masque_a, 3, p, 0.7));
		vec2 q = p + vec2(n1(p * 0.035 + 3.0), n1(p * 0.035 + 8.0)) * 2.2;
		float u = dot(q, vec2(0.8, 0.6)) * 0.6;
		float f = fract(u);
		cs = mix(cs, SABLE_MOUILLE, smoothstep(0.0, 0.03, f) * (1.0 - smoothstep(0.03, 0.5, f)) * 0.5 * large);
		cs = mix(cs, SABLE_CLAIR, smoothstep(0.6, 0.98, f) * 0.45 * large);
		float wu = max(fwidth(u), 1e-4);
		float crete = 1.0 - smoothstep(k * 0.3, k * 0.3 + 1.0, min(f, 1.0 - f) / wu);
		cs = mix(cs, SABLE_MOUILLE * 0.75, crete * 0.55 * large * smoothstep(0.35, 0.5, n1(p * 0.12 + 2.0)));
		// sable caillouteux : petits galets semés par zones
		float zone = smoothstep(0.6, 0.68, n1(p * 0.07 + 40.0)) * (1.0 - large) * smoothstep(30.0, 60.0, ppc);
		vec2 g = p * 5.5; vec2 id = floor(g);
		float d = length((g - id - 0.5 - (vec2(h21(id + 6.0), h21(id + 9.0)) - 0.5) * 0.5) * vec2(1.0, 1.35));
		float sel = step(0.55, h21(id + 13.0)) * zone;
		cs = mix(cs, mix(vec3(0.78, 0.74, 0.66), vec3(0.66, 0.62, 0.55), h21(id + 2.0)), (1.0 - smoothstep(0.1, 0.13, d)) * sel);
		cs = mix(cs, ENCRE, (smoothstep(0.1, 0.13, d) - smoothstep(0.15, 0.18, d)) * sel * 0.7);
		// laisse de rivage : ligne pointillée de débris un peu en retrait de l'eau
		float laisse = encre(pres_eau + 0.13, 0.9) * step(0.45, n1(p * 1.6 + 4.0));
		cs = mix(cs, BERGE * 0.85, laisse * 0.55 * smoothstep(30.0, 60.0, ppc));
	}
	if (ax_geographie) {
		// plage : sable mouillé du côté de l'eau ; ailleurs, halo de prairie sèche autour du sable
		cs = mix(cs, SABLE_MOUILLE, smoothstep(0.18, 0.5, pres_eau) * 0.75);
		float halo = smoothstep(0.25, 0.5, vs) * (1.0 - dedans(vs));
		c = mix(c, HERBE_SECHE, halo * 0.4 * (1.0 - smoothstep(0.1, 0.35, pres_eau)));
	}
	c = mix(c, cs, dedans(vs)); c = mix(c, ENCRE, encre(vs, k_plat) * a_plat * (ax_geographie ? 1.0 - 0.2 * smoothstep(0.1, 0.4, 1.0 - pres_eau) : 1.0));

	// ---------- rocaille (et gisement d'or)
	float vr = max(champ(masque_a, 2, p, 0.5), champ(masque_b, 1, p, 0.3)) + touffe;
	vec2 p_roche = p;
	vec3 cr = mix(ROCHE, ROCHE_SOMBRE, dedans(n1(p * 0.15 + 5.0) + 0.05));
	if (ax_matieres) {
		// grandes plaques de teinte (pierre claire / pierre sombre) sous les galets
		cr = mix(cr, vec3(0.80, 0.78, 0.72), dedans(n1(p * 0.07 + 2.5) - 0.06) * 0.35);
	}
	vec4 dro = detail(tex_roche, p_roche); dro.a *= lod_roche;
	cr = sur(cr, dro);
	c = mix(c, cr, dedans(vr)); c = mix(c, ENCRE, encre(vr, k_plat) * a_plat);
	if (ax_geographie) {
		// éboulis : cailloux semés autour de la rocaille
		vec2 g = p * 4.0; vec2 id = floor(g);
		float d = length(g - id - 0.5 - (vec2(h21(id), h21(id + 1.7)) - 0.5) * 0.5);
		float bande = step(0.22, brut(masque_a, 2, p)) * (1.0 - dedans(vr + 0.08)) * (1.0 - dedans(vs)) * smoothstep(30.0, 60.0, ppc);
		float sel = step(0.6, h21(id + 4.4));
		float caillou = (1.0 - smoothstep(0.09, 0.12, d)) * sel * bande;
		c = mix(c, ROCHE_SOMBRE, caillou);
		c = mix(c, ENCRE, (smoothstep(0.09, 0.12, d) - smoothstep(0.14, 0.17, d)) * sel * bande * 0.85);
	}

	// ---------- sol de forêt (les arbres sont des sprites posés dessus)
	float vf = champ(masque_a, 1, p, 0.55) + touffe;
	vec3 cf = sur(SOL_FORET, vec4(detail(tex_herbe, p).rgb * 0.7, detail(tex_herbe, p).a * 0.6 * lod));
	c = mix(c, cf, dedans(vf)); c = mix(c, ENCRE, encre(vf, k_plat) * 0.7 * (ax_contours ? 0.6 : 1.0));
	if (ax_relief) {
		// ombre de la forêt vers le sud-est (lumière du nord-ouest)
		vec2 d_for = ax_journee ? dir_ombre * 0.62 : vec2(0.22, 0.32);
		float om = dedans(champ(masque_a, 1, p - d_for, 0.55)) * (1.0 - dedans(vf));
		c = mix(c, c * 0.84, om * 0.6);
	}

	// ---------- chemins
	float vc = champ(masque_b, 2, p, 0.12);
	vec3 cc = mix(CHEMIN_BORD, CHEMIN, smoothstep(0.62, 0.72, vc));
	cc = mix(cc, CHEMIN_BORD, step(0.985, n1(p * 1.7)) * 0.8);
	c = mix(c, cc, dedans(vc)); c = mix(c, ENCRE, encre(vc, k) * 0.85);

	// ---------- eau : berge visible au nord, surface plus basse, profondeur en paliers
	float ve = champ(masque_a, 0, p, 0.35);
	vec2 ps = p - vec2(0.0, decalage_eau);
	float vsurf = champ(masque_a, 0, ps, 0.35);
	float prof = texture(masque_c, ps / taille_carte).r;
	vec3 ce = EAU_HAUT_FOND;
	if (ax_eau) {
		// dégradé continu turquoise → bleu profond, avec des paliers adoucis
		float pr = prof + (n1(ps * 0.3) - 0.5) * 0.1;
		// paliers nets (style BD) : turquoise au bord, puis trois bleus de plus en plus profonds
		ce = mix(EAU_TURQUOISE, EAU_HAUT_FOND, smoothstep(0.04, 0.07, pr));
		ce = mix(ce, EAU, smoothstep(0.15, 0.18, pr));
		ce = mix(ce, EAU_2, smoothstep(0.4, 0.43, pr));
		ce = mix(ce, EAU_3, smoothstep(0.72, 0.75, pr));
	} else {
		ce = mix(ce, EAU, step(0.12, prof + (n1(ps * 0.3) - 0.5) * 0.08));
		ce = mix(ce, EAU_2, step(0.38, prof + (n1(ps * 0.3) - 0.5) * 0.1));
		ce = mix(ce, EAU_3, step(0.7, prof + (n1(ps * 0.3) - 0.5) * 0.1));
	}
	vec4 info_eau = texture(masque_c, ps / taille_carte);
	if (ax_eaux) {
		// mares : eau verte et trouble ; lacs : inchangés (plus clairs par contraste)
		vec3 vert = mix(vec3(0.47, 0.70, 0.55), vec3(0.32, 0.56, 0.46), smoothstep(0.08, 0.4, prof));
		ce = mix(ce, vert, info_eau.g * 0.8);
	}
	vec4 de = detail(tex_eau, ps + vec2(temps_eau * 0.05, 0.0));
	de.a *= ax_lod ? mix(0.5, 1.0, pres) : 1.0;
	ce = sur(ce, de);
	float ecume;
	if (ax_eau) {
		// écume continue le long de la rive + second liseré qui respire
		ecume = encre(vsurf, k * 2.2) * 0.9;
		float r2 = encre(vsurf - 0.13 - 0.03 * sin(temps_eau * 0.8 + n1(ps * 0.4) * 6.0), k * 0.9);
		ecume = max(ecume, r2 * 0.45 * step(0.4, n1(ps * 0.7)));
		// reflets : petits éclats qui scintillent en eau profonde
		vec2 g = ps * 2.4; vec2 id = floor(g);
		float ph = h21(id);
		vec2 o = g - id - 0.5;
		float eclat = (1.0 - smoothstep(0.02, 0.06, abs(o.y))) * (1.0 - smoothstep(0.1, 0.22, abs(o.x)));
		eclat *= step(0.82, ph) * smoothstep(0.3, 0.6, prof) * (0.5 + 0.5 * sin(temps_eau * 2.0 + ph * 40.0));
		ce = mix(ce, vec3(1.0), eclat * 0.8);
		// nénuphars en eau peu profonde
		vec2 gn = ps * 1.15; vec2 idn = floor(gn);
		float rn = h21(idn + 2.2);
		vec2 cn = idn + 0.5 + (vec2(h21(idn + 5.1), h21(idn + 8.3)) - 0.5) * 0.5;
		vec2 dv = gn - cn;
		float dn = length(dv);
		float rad = 0.17 + 0.07 * h21(idn + 9.9);
		float ang = atan(dv.y, dv.x) + rn * 6.28;
		float encoche = step(0.92, cos(ang));
		float ok = step(0.8, rn) * step(0.06, prof) * (1.0 - step(0.42, prof));
		float feuille = (1.0 - smoothstep(rad - 0.02, rad, dn)) * (1.0 - encoche) * ok;
		ce = mix(ce, NENUPHAR, feuille);
		ce = mix(ce, ENCRE, (smoothstep(rad - 0.03, rad, dn) - smoothstep(rad, rad + 0.03, dn)) * (1.0 - encoche) * ok * 0.8);
		float fleur = (1.0 - smoothstep(0.03, 0.05, length(dv - vec2(rad * 0.25)))) * ok * step(0.93, rn);
		ce = mix(ce, vec3(0.98, 0.78, 0.86), fleur);
	} else {
		ecume = encre(vsurf, k * 2.6) * step(0.45, n1(ps * 0.9 + vec2(temps_eau * 0.02)));
	}
	if (ax_eaux) {
		// courant dans les bras étroits : traits clairs qui filent dans le sens du bras
		float cour = max(info_eau.b, info_eau.a);
		vec2 dirc = info_eau.b > info_eau.a ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
		vec2 perp = vec2(-dirc.y, dirc.x);
		vec2 cg = vec2(dot(ps, dirc) * 1.3 - temps_eau * 0.45, dot(ps, perp) * 4.0 + n1(ps * 0.5) * 1.5);
		vec2 cid = floor(cg);
		float seg = fract(cg.x + h21(vec2(cid.y, 3.0)) * 7.0);
		float filet = (1.0 - smoothstep(0.05, 0.11, abs(fract(cg.y) - 0.5))) * step(0.5, seg) * (1.0 - step(0.82, seg)) * step(0.45, h21(vec2(cid.y, 1.0)));
		ce = mix(ce, vec3(0.93, 0.98, 1.0), filet * smoothstep(0.3, 0.7, cour) * 0.65 * smoothstep(0.03, 0.08, prof));
	}
	ce = mix(ce, vec3(1.0), ecume * 0.85);
	vec3 cb = mix(BERGE, BERGE * 0.82, step(0.5, fract(p.x * 3.0 + n1(p * 0.5) * 2.0)) * 0.5);
	if (ax_relief) {
		// berge : terre plus sombre en bas, herbe qui retombe en haut
		cb = mix(cb, cb * 0.72, smoothstep(0.35, 0.65, champ(masque_a, 0, p + vec2(0.0, 0.18), 0.35)));
	}
	float in_e = dedans(ve);
	c = mix(c, mix(cb, ce, dedans(vsurf)), in_e);
	c = mix(c, ENCRE, encre(vsurf, k * 0.8) * in_e * 0.6);
	c = mix(c, ENCRE, encre(ve, k_relief * 1.6));

	// ---------- ponts (planches au-dessus de l'eau)
	float vp = texture(masque_b, p / taille_carte).a;
	float in_p = dedans(vp * 1.15);
	vec3 cp = mix(PLANCHE, PLANCHE * 0.7, step(0.86, fract(p.y * 5.0)));
	c = mix(c, cp, in_p); c = mix(c, ENCRE, encre(vp * 1.15, k));

	// ---------- montagnes : plateau surélevé, falaise au sud, dessus rocheux
	float h = hauteur_falaise;
	if (ax_geographie) {
		// éboulis au pied des massifs
		float pied = smoothstep(0.15, 0.48, brut(masque_b, 0, p)) * (1.0 - dedans(champ(masque_b, 0, p, 0.3)));
		vec2 g = p * 3.6; vec2 id = floor(g);
		float d = length(g - id - 0.5 - (vec2(h21(id + 3.0), h21(id + 6.0)) - 0.5) * 0.5);
		pied *= smoothstep(30.0, 60.0, ppc);
		float cail = (1.0 - smoothstep(0.1, 0.13, d)) * step(0.5, h21(id + 1.1)) * pied;
		c = mix(c, mix(ROCHE, ROCHE_SOMBRE, h21(id)), cail);
		c = mix(c, ENCRE, (smoothstep(0.1, 0.13, d) - smoothstep(0.15, 0.18, d)) * step(0.5, h21(id + 1.1)) * pied * 0.85);
	}
	if (ax_relief) {
		// ombre portée du massif vers le sud-est, sur tout ce qui l'entoure
		float om = dedans(champ(masque_b, 0, p - (ax_journee ? dir_ombre : vec2(0.45, 0.35)), 0.3));
		c = mix(c, c * 0.7, om * 0.8 * (1.0 - dedans(champ(masque_b, 0, p, 0.3))));
	}
	float vtop = champ(masque_b, 0, p + vec2(0.0, h), 0.3);
	float face = 0.0; float rel = 0.0;
	for (int i = 0; i <= 6; i++) {
		float t = h * float(i) / 6.0;
		float vi = dedans(champ(masque_b, 0, p + vec2(0.0, t), 0.3));
		if (vi > 0.5 && face < 0.5) { rel = float(i) / 6.0; }
		face = max(face, vi);
	}
	vec3 cfa = mix(FALAISE_BAS, FALAISE_HAUT, rel);
	cfa = sur(cfa, detail(tex_falaise, vec2(p.x, p.y * 0.6)));
	if (ax_relief) {
		// strates horizontales et lumière rasante sur la face
		float strate = encre(fract(rel * 2.6 + (n1(vec2(p.x * 0.4, 0.0)) - 0.5) * 0.5), 0.8);
		cfa = mix(cfa, ENCRE, strate * 0.25 * pres);
		cfa *= mix(0.92, 1.08, smoothstep(0.3, 0.7, n1(vec2(p.x * 0.8, 3.0))));
	}
	float col_c = floor(p.x * 2.2);
	float x_c = fract(p.x * 2.2);
	float sel_c = step(0.5, h21(vec2(col_c, 9.0)));
	if (ax_massifs) {
		// cascade : là où la falaise tombe dans l'eau, filets d'eau verticaux qui descendent
		float eau_dessous = brut(masque_a, 0, vec2(p.x, floor(p.y + 0.6) + 0.5));
		float cas = face * step(0.5, eau_dessous) * sel_c * (1.0 - smoothstep(0.22, 0.3, abs(x_c - 0.5)));
		float voie = floor(x_c * 6.0);
		float filet_c = step(0.45, fract(p.y * 3.0 - temps_eau * 1.8 + h21(vec2(col_c, voie)) * 5.0));
		vec3 cc2 = mix(vec3(0.62, 0.84, 0.95), vec3(0.97, 0.99, 1.0), filet_c * step(0.35, fract(x_c * 6.0)));
		cfa = mix(cfa, cc2, cas);
		float bordc = smoothstep(0.2, 0.23, abs(x_c - 0.5)) - smoothstep(0.27, 0.3, abs(x_c - 0.5));
		cfa = mix(cfa, ENCRE, cas * bordc * 0.7);
	}
	vec3 cto = sur(MONT_DESSUS, detail(tex_roche, ax_matieres ? p * 0.8 + vec2(1.9, 0.4) : p) * vec4(1.0, 1.0, 1.0, lod_roche));
	if (ax_relief) {
		// arête éclairée côté nord-ouest, plateau un peu plus sombre côté sud-est
		float arete = dedans(vtop) * (1.0 - dedans(champ(masque_b, 0, p + vec2(0.0, h) + vec2(-0.22, -0.22), 0.3)));
		cto = mix(cto, vec3(0.86, 0.84, 0.78), arete * 0.7);
		float cote_sombre = dedans(vtop) * (1.0 - dedans(champ(masque_b, 0, p + vec2(0.0, h) + vec2(0.3, 0.3), 0.3)));
		cto = mix(cto, cto * 0.84, cote_sombre * 0.7);
	}
	if (ax_massifs) {
		// mousse sur le versant nord du plateau, lichens jaunes semés
		float nord = dedans(vtop) * (1.0 - dedans(champ(masque_b, 0, p + vec2(0.0, h) - vec2(0.0, 0.5), 0.3)));
		cto = mix(cto, vec3(0.52, 0.63, 0.40), nord * smoothstep(0.42, 0.58, n1(p * 0.5 + 17.0)) * 0.7);
		vec2 gl = p * 6.0; vec2 il = floor(gl);
		float dl = length(gl - il - 0.5);
		cto = mix(cto, vec3(0.86, 0.72, 0.35), (1.0 - smoothstep(0.08, 0.14, dl)) * step(0.93, h21(il + 21.0)) * smoothstep(40.0, 80.0, ppc) * 0.75);
	}
	c = mix(c, cfa, face);
	c = mix(c, cto, dedans(vtop));
	c = mix(c, ENCRE, encre(vtop, k_relief * 1.4));
	float vbas = champ(masque_b, 0, p, 0.3);
	c = mix(c, ENCRE, encre(vbas, k_relief * 1.4) * face);

	if (ax_massifs) {
		// écume au pied des cascades
		float sous = step(0.5, brut(masque_b, 0, p - vec2(0.0, 0.5))) * (1.0 - face) * in_e * dedans(vsurf);
		float ec = sous * sel_c * (1.0 - smoothstep(0.25, 0.5, abs(x_c - 0.5))) * smoothstep(0.42, 0.58, n1(p * 2.2 + vec2(0.0, -temps_eau * 0.35)));
		ec *= 1.0 - smoothstep(0.0, 0.45, fract(p.y - 0.5));
		c = mix(c, vec3(1.0), ec * 0.85);
	}

	// ---------- vie : ombres de nuages qui glissent
	if (ax_vie) {
		float nu = n1(p * 0.009 + vec2(temps_eau * 0.0035, temps_eau * 0.0018));
		nu = smoothstep(0.58, 0.7, nu + (n1(p * 0.03 + 5.5) - 0.5) * 0.08);
		c *= 1.0 - 0.13 * nu;
	}

	COLOR = vec4(c, 1.0);
}
