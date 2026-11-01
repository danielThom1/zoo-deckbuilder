// Sol de la carte, style « BD néo ligne claire en semi-perspective ».
// Une case = 1 unité dans les coordonnées « p ». Les masques (1 texel par case, filtrage linéaire)
// donnent des bords arrondis ; le bruit les rend organiques ; l'encre suit les bords à épaisseur constante à l'écran.
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

const vec3 ENCRE = vec3(0.078, 0.125, 0.169);          // #14202B
const vec3 HERBE = vec3(0.549, 0.761, 0.353);          // #8CC25A
const vec3 HERBE_SOMBRE = vec3(0.498, 0.714, 0.310);   // #7FB64F
const vec3 HERBE_CLAIRE = vec3(0.616, 0.796, 0.400);   // #9DCB66
const vec3 LISIERE = vec3(0.431, 0.647, 0.282);        // #6EA548
const vec3 SOL_FORET = vec3(0.369, 0.569, 0.271);      // #5E9145
const vec3 SABLE = vec3(0.914, 0.808, 0.541);          // #E9CE8A
const vec3 SABLE_CLAIR = vec3(0.953, 0.867, 0.643);    // #F3DDA4
const vec3 ROCHE = vec3(0.741, 0.722, 0.667);          // #BDB8AA
const vec3 ROCHE_SOMBRE = vec3(0.655, 0.631, 0.576);   // #A7A193
const vec3 BERGE = vec3(0.557, 0.478, 0.353);          // #8E7A5A
const vec3 EAU_HAUT_FOND = vec3(0.486, 0.800, 0.902);  // #7CCCE6
const vec3 EAU = vec3(0.275, 0.663, 0.839);            // #46A9D6
const vec3 EAU_2 = vec3(0.180, 0.549, 0.769);          // #2E8CC4
const vec3 EAU_3 = vec3(0.133, 0.447, 0.659);          // #2272A8
const vec3 CHEMIN = vec3(0.902, 0.796, 0.580);         // #E6CB94
const vec3 CHEMIN_BORD = vec3(0.788, 0.643, 0.408);    // #C9A468
const vec3 PLANCHE = vec3(0.722, 0.525, 0.306);        // #B8864E
const vec3 FALAISE_HAUT = vec3(0.678, 0.631, 0.565);   // #ADA190
const vec3 FALAISE_BAS = vec3(0.373, 0.341, 0.294);    // #5F574B
const vec3 MONT_DESSUS = vec3(0.639, 0.612, 0.549);    // #A39C8C

float n1(vec2 q) { return texture(bruit, q).r; }

// Valeur lissée d'un masque + bruit ; 0.5 = bord.
float champ(sampler2D m, int canal, vec2 p, float amp) {
	vec4 v = texture(m, p / taille_carte);
	float x = canal == 0 ? v.r : canal == 1 ? v.g : canal == 2 ? v.b : v.a;
	float n = (n1(p * 0.045) - 0.5) * 0.9 + (n1(p * 0.19 + 0.37) - 0.5) * 0.35;
	return x + n * amp;
}
float dedans(float v) { float w = max(fwidth(v), 1e-4); return smoothstep(0.5 - w, 0.5 + w, v); }
float encre(float v, float k) { float w = max(fwidth(v), 1e-4); return 1.0 - smoothstep(k * 0.5, k * 0.5 + 1.0, abs(v - 0.5) / w); }
vec4 detail(sampler2D t, vec2 p) { return texture(t, p / 4.0); }
vec3 sur(vec3 c, vec4 d) { return mix(c, d.rgb, d.a); }

void fragment() {
	vec2 p = UV * taille_carte;
	float k = epaisseur_encre;

	// ---------- prairie : trois tons en taches, liseré discret, détails dessinés
	float t1 = n1(p * 0.06 + 3.1); float t2 = n1(p * 0.06 + 7.7);
	vec3 c = HERBE;
	float pa = dedans(t1 + 0.12); c = mix(c, HERBE_SOMBRE, pa);
	float pb = dedans(t2 - 0.16); c = mix(c, HERBE_CLAIRE, pb);
	c = mix(c, ENCRE, 0.18 * max(encre(t1 + 0.12, 0.8), encre(t2 - 0.16, 0.8)));
	float f_brut = texture(masque_a, p / taille_carte).g;
	c = mix(c, LISIERE, smoothstep(0.08, 0.45, f_brut) * 0.8);
	vec4 dh = detail(tex_herbe, p);
	vec4 dh2 = detail(tex_herbe, p * 0.77 + vec2(1.3, 2.1));
	c = sur(c, n1(p * 0.11) > 0.5 ? dh : dh2);

	// ---------- sable
	float vs = champ(masque_a, 3, p, 0.5);
	vec3 cs = mix(SABLE, SABLE_CLAIR, smoothstep(0.75, 0.95, vs));
	cs = sur(cs, detail(tex_sable, p));
	c = mix(c, cs, dedans(vs)); c = mix(c, ENCRE, encre(vs, k));

	// ---------- rocaille (et gisement d'or)
	float vr = max(champ(masque_a, 2, p, 0.5), champ(masque_b, 1, p, 0.3));
	vec3 cr = mix(ROCHE, ROCHE_SOMBRE, dedans(n1(p * 0.15 + 5.0) + 0.05));
	cr = sur(cr, detail(tex_roche, p));
	c = mix(c, cr, dedans(vr)); c = mix(c, ENCRE, encre(vr, k));

	// ---------- sol de forêt (les arbres sont des sprites posés dessus)
	float vf = champ(masque_a, 1, p, 0.55);
	vec3 cf = sur(SOL_FORET, vec4(detail(tex_herbe, p).rgb * 0.7, detail(tex_herbe, p).a * 0.6));
	c = mix(c, cf, dedans(vf)); c = mix(c, ENCRE, encre(vf, k) * 0.7);

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
	ce = mix(ce, EAU, step(0.12, prof + (n1(ps * 0.3) - 0.5) * 0.08));
	ce = mix(ce, EAU_2, step(0.38, prof + (n1(ps * 0.3) - 0.5) * 0.1));
	ce = mix(ce, EAU_3, step(0.7, prof + (n1(ps * 0.3) - 0.5) * 0.1));
	vec4 de = detail(tex_eau, ps + vec2(temps_eau * 0.05, 0.0));
	ce = sur(ce, de);
	float ecume = encre(vsurf, k * 2.6) * step(0.45, n1(ps * 0.9 + vec2(temps_eau * 0.02)));
	ce = mix(ce, vec3(1.0), ecume * 0.85);
	vec3 cb = mix(BERGE, BERGE * 0.82, step(0.5, fract(p.x * 3.0 + n1(p * 0.5) * 2.0)) * 0.5);
	float in_e = dedans(ve);
	c = mix(c, mix(cb, ce, dedans(vsurf)), in_e);
	c = mix(c, ENCRE, encre(vsurf, k * 0.8) * in_e * 0.6);
	c = mix(c, ENCRE, encre(ve, k * 1.6));

	// ---------- ponts (planches au-dessus de l'eau)
	float vp = texture(masque_b, p / taille_carte).a;
	float in_p = dedans(vp * 1.15);
	vec3 cp = mix(PLANCHE, PLANCHE * 0.7, step(0.86, fract(p.y * 5.0)));
	c = mix(c, cp, in_p); c = mix(c, ENCRE, encre(vp * 1.15, k));

	// ---------- montagnes : plateau surélevé, falaise au sud, dessus rocheux
	float h = hauteur_falaise;
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
	vec3 cto = sur(MONT_DESSUS, detail(tex_roche, p));
	c = mix(c, cfa, face);
	c = mix(c, cto, dedans(vtop));
	c = mix(c, ENCRE, encre(vtop, k * 1.4));
	float vbas = champ(masque_b, 0, p, 0.3);
	c = mix(c, ENCRE, encre(vbas, k * 1.4) * face);

	COLOR = vec4(c, 1.0);
}
