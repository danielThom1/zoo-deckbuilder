// Arbres et buissons au vent (axe « vie » de CarteBD.AXES) : le haut du sprite oscille, le pied reste fixe.
shader_type canvas_item;

uniform float force = 1.0;

void vertex() {
	vec2 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float ph = o.x * 0.011 + o.y * 0.006;
	float haut = 1.0 - UV.y;
	VERTEX.x += (sin(TIME * 1.5 + ph * 6.2832) + 0.35 * sin(TIME * 3.7 + ph * 11.0)) * 5.0 * force * haut * haut;
}
