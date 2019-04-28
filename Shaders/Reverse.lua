	local pixelcode = [[
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		vec4 texturecolor = Texel(texture, texture_coords);
		return vec4(1-texturecolor.x,1-texturecolor.y,1-texturecolor.z,texturecolor.w) * color;
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