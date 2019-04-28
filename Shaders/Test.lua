	local pixelcode = [[
    extern float MODIFIER;
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
		vec4 ORIGtexcolor = Texel(texture, texture_coords);
		float MOD=MODIFIER;
		while (MOD-abs((texture_coords.x-0.5)*MOD)>0.75 && MOD-abs((texture_coords.y-0.5)*MOD)>0.75) MOD=MOD-0.75;
		if (MOD>0.75) MOD=0.25+0.5*MOD/0.75;
		if (MOD>1) MOD=1;
		texture_coords.x=texture_coords.x-(texture_coords.x-0.5)*MOD;
		texture_coords.y=texture_coords.y-(texture_coords.y-0.5)*MOD;
        vec4 texcolor = Texel(texture, texture_coords);
		if (texcolor.z>0.5)
			return texcolor * color;
		else
			return ORIGtexcolor * color;
    }
	]]
 
	local vertexcode = [[
    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
		mat4 TRANSFORM=mat4(1,0,0,0,
							0,1,0,0,
							0,0,1,0,
							0,0,0,1) ;
        return (transform_projection * TRANSFORM) * vertex_position ;
    }
	]]
 
	return love.graphics.newShader(pixelcode, vertexcode)