	
	local pixelcode = [[
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		vec4 texturecolor = Texel(texture, texture_coords);
		return texturecolor * color;
	}
	]]
	
	local vertexcode = [[
    extern vec4 Target;
    extern number TargetSide;
	vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
	number A=TargetSide;
	if (A==1)
		{if (VertexTexCoord.y==0 && VertexTexCoord.x==0) vertex_position=vec4(Target.x,Target.y,0,1);
		else if (VertexTexCoord.y==0 && VertexTexCoord.x==1) vertex_position=vec4(Target.z,Target.w,0,1);
		else if (VertexTexCoord.y==0 && VertexTexCoord.x==0.5) vertex_position=vec4((Target.x+Target.z)/2,(Target.y+Target.w)/2,0,1);
		else if (VertexTexCoord.y==0.5 && VertexTexCoord.x==0.5) vertex_position=vec4((Target.x+Target.z+vertex_position.x+vertex_position.x)/4,(Target.y+Target.w+vertex_position.y*4)/4,0,1);
		else if (VertexTexCoord.y==0.5 && VertexTexCoord.x==0) vertex_position=vec4((Target.x+vertex_position.x)/2,(Target.y+vertex_position.y*2)/2,0,1);
		else if (VertexTexCoord.y==0.5 && VertexTexCoord.x==1) vertex_position=vec4((Target.z+vertex_position.x)/2,(Target.w+vertex_position.y*2)/2,0,1);}
	else
		{if (VertexTexCoord.y==1 && VertexTexCoord.x==0) vertex_position=vec4(Target.x,Target.y,0,1);
		else if (VertexTexCoord.y==1 && VertexTexCoord.x==1) vertex_position=vec4(Target.z,Target.w,0,1);
		else if (VertexTexCoord.y==1 && VertexTexCoord.x==0.5) vertex_position=vec4((Target.x+Target.z)/2,(Target.y+Target.w)/2,0,1);
		else if (VertexTexCoord.y==0.5 && VertexTexCoord.x==0.5) vertex_position=vec4((Target.x+Target.z+vertex_position.x+vertex_position.x)/4,(Target.y+Target.w)/4,0,1);
		else if (VertexTexCoord.y==0.5 && VertexTexCoord.x==0) vertex_position=vec4((Target.x+vertex_position.x)/2,(Target.y)/2,0,1);
		else if (VertexTexCoord.y==0.5 && VertexTexCoord.x==1) vertex_position=vec4((Target.z+vertex_position.x)/2,(Target.w)/2,0,1);}
        return (transform_projection) * vertex_position;
    }
	]]
	
	return love.graphics.newShader(pixelcode, vertexcode)