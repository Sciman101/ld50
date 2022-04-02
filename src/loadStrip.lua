return function(filename,frames,speed)

	local sprite = love.graphics.newImage(filename)
	local w = sprite:getWidth()
	local h = sprite:getHeight()
	local yy = h/frames
	local quads = {}
	for i=1,frames do
		quads[i] = love.graphics.newQuad(0,yy*(i-1),w,yy,sprite)
	end
	return {sprite=sprite,frames=quads}

end