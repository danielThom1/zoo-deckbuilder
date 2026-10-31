// Eau stylisée « Émeraude » : bleu profond au centre, turquoise sur les bords, liseré d'écume.
// Utilise la texture de profondeur (Godot 4.3+, rendu Forward+ ou Mobile).
// Point de départ non testé dans le projet.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;

uniform vec4 couleur_profonde : source_color = vec4(0.039, 0.243, 0.541, 1.0); // #0A3E8A
uniform vec4 couleur_moyenne : source_color = vec4(0.071, 0.408, 0.722, 1.0); // #1268B8
uniform vec4 couleur_bord : source_color = vec4(0.118, 0.604, 0.784, 1.0);    // #1E9AC8
uniform vec4 couleur_berge : source_color = vec4(0.275, 0.878, 0.847, 1.0);   // #46E0D8
uniform vec4 couleur_ecume : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float profondeur_bord = 1.5;   // en mètres : distance sur laquelle on passe de la berge au profond
uniform float largeur_ecume = 0.12;    // en mètres
uniform float vitesse = 0.03;
uniform sampler2D carte_normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
	float profondeur = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, profondeur);
	vec4 vue = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vue.xyz /= vue.w;
	float ecart = max(VERTEX.z - vue.z, 0.0); // épaisseur d'eau vue depuis la caméra

	float t = clamp(ecart / profondeur_bord, 0.0, 1.0);
	vec3 couleur = mix(couleur_berge.rgb, couleur_bord.rgb, smoothstep(0.0, 0.25, t));
	couleur = mix(couleur, couleur_moyenne.rgb, smoothstep(0.25, 0.6, t));
	couleur = mix(couleur, couleur_profonde.rgb, smoothstep(0.6, 1.0, t));
	float ecume = 1.0 - smoothstep(0.0, largeur_ecume, ecart);
	couleur = mix(couleur, couleur_ecume.rgb, ecume * 0.75);

	vec2 uv = UV * 6.0;
	vec3 n1 = texture(carte_normale, uv + vec2(TIME * vitesse, 0.0)).rgb;
	vec3 n2 = texture(carte_normale, uv * 0.7 - vec2(0.0, TIME * vitesse * 0.8)).rgb;
	NORMAL_MAP = mix(n1, n2, 0.5);

	ALBEDO = couleur;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
	ALPHA = mix(0.8, 0.96, t);
}
