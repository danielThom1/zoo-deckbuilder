// Grille du mode construction, dessinée en espace monde sur un plan posé au-dessus du terrain
// (ou en décalque). Visible seulement en mode construction : piloter `opacite` de 0 à 1.
// Point de départ non testé dans le projet.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float taille_case = 1.0;
uniform float epaisseur_px = 1.5;
uniform vec4 couleur_ligne : source_color = vec4(1.0, 1.0, 1.0, 0.32);
uniform vec2 carte_min = vec2(0.0, 0.0);
uniform vec2 carte_max = vec2(64.0, 64.0);
uniform float opacite : hint_range(0.0, 1.0) = 1.0;

varying vec3 pos_monde;

void vertex() {
	pos_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = pos_monde.xz / taille_case;
	vec2 d = abs(fract(p - 0.5) - 0.5) / max(fwidth(p), vec2(1e-5));
	float ligne = 1.0 - clamp(min(d.x, d.y) / epaisseur_px, 0.0, 1.0);
	float dedans = step(carte_min.x, pos_monde.x) * step(pos_monde.x, carte_max.x)
		* step(carte_min.y, pos_monde.z) * step(pos_monde.z, carte_max.y);
	ALBEDO = couleur_ligne.rgb;
	ALPHA = couleur_ligne.a * ligne * dedans * opacite;
}
