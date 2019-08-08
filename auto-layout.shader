uniform bool setup_mode = true;
uniform float field_left_x = 96;
uniform float field_right_x = 176;
uniform float field_top_y = 43;
uniform float field_bottom_y = 196;

uniform float game_black_x1 = 98;
uniform float game_black_y1 = 26;
uniform float game_black_x2 = 240;
uniform float game_black_y2 = 24;
uniform float game_grey_x1 = 36;
uniform float game_grey_y1 = 214;

float2 top_left_f()
{
    return float2(field_left_x / 256.0, field_top_y / 224.0);
}

float2 bot_right_f()
{
    return float2(field_right_x / 256.0, field_bottom_y / 224.0);
}

float myLerp(float start, float end, float perc)
{
    return start + (end-start) * perc;
}

float invLerp(float start, float end, float num)
{
    return (num-start) / (end-start);
}

float2 invLerp2(float2 start, float2 end, float2 num)
{
    return float2(invLerp(start.x,end.x,num.x),
                  invLerp(start.y,end.y,num.y));
}

//width as portion of full screen width.
float blockWidth() {
	return (field_right_x - field_left_x) / 10.0 / 256.0;
}

float blockHeight() {
	return (field_bottom_y - field_top_y) / 20.0 / 224.0;
}


float pixelWidthUV()
{
	float bw = blockWidth();
	return bw/8.0;
}

float pixelHeightUV()
{
	float bh = blockHeight();
	return bh/8.0;
}

float pixelUV()
{
	return float2(pixelWidthUV(),pixelHeightUV());
}

bool inField(float2 uv) {	
	float startX = field_left_x / 256.0;
	float endX = field_right_x / 256.0;
	float startY = field_top_y / 224.0;
	float endY = field_bottom_y / 224.0;
	return (uv.x > startX && uv.x < endX && uv.y > startY && uv.y < endY);
}

bool inBox2(float2 uv, float4 box)
{
	return (uv.x >= box.r && 
			uv.x <= box.g && 
			uv.y >= box.b && 
			uv.y <= box.a);
}

float4 pixBox(float2 uv, int pixels)
{
	return float4(uv.x - (pixels / 256.0), uv.x + (pixels/256.0),
				  uv.y - (pixels / 224.0), uv.y + (pixels/224.0));
}

float2 gameBlack1_uv() { return float2(game_black_x1 / 256.0, game_black_y1 / 224.0); }
float2 gameBlack2_uv() { return float2(game_black_x2 / 256.0, game_black_y2 / 224.0); }
float2 gameGrey1_uv() { return float2(game_grey_x1 / 256.0, game_grey_y1 / 224.0); }

float4 gameBlack1_box(){ return pixBox(gameBlack1_uv(), 2);}
float4 gameBlack2_box(){ return pixBox(gameBlack2_uv(), 2);}
float4 gameGrey1_box() { return pixBox(gameGrey1_uv(), 2);}

bool isBlack(float4 rgba) {
	float limit = 0.15;
	return (rgba.r <= limit &&
			rgba.g <= limit &&
			rgba.b <= limit);
}

bool isGrey(float4 rgba) {
	float limit = 0.25;
	return (rgba.r >= 0.5 - limit && rgba.r <= 0.5 + limit &&
			rgba.g >= 0.5 - limit && rgba.g <= 0.5 + limit &&
			rgba.b >= 0.5 - limit && rgba.b <= 0.5 + limit);
	
}

bool isBlue(float4 rgba)
{
    float limit = 0.25;
    return rgba.b >= 1.0 - limit && rgba.r <= limit && rgba.g <= limit;
}

//Simple 4 sample of centre of 3x3 block
float4 sampleBlock(float2 uv, float2 pixelSize)
{	
	float4 centre = image.Sample(textureSampler, uv);
	//float4 tl = image.Sample(textureSampler,float2(uv.x - pixelSize.x, uv.y - pixelSize.y));
	float4 tr = image.Sample(textureSampler,float2(uv.x + pixelSize.x, uv.y - pixelSize.y));
	float4 r = image.Sample(textureSampler,float2(uv.x + pixelSize.x, uv.y));
	float4 bl = image.Sample(textureSampler,float2(uv.x - pixelSize.x, uv.y + pixelSize.y));
	float4 br = image.Sample(textureSampler,float2(uv.x + pixelSize.x, uv.y + pixelSize.y));
	float4 avg = (tr + bl + br + centre + r) / 5.0;
	//avg = centre;
	return avg;
}



float4 setupDraw(float2 uv)
{
	float2 pixelSize = pixelUV();
	
	float4 orig = image.Sample(textureSampler, uv);
	if (inField(uv))
	{		
		return (float4(1.0,0.0,0.0,1.0) + orig) / 2.0;	
	} 
	
	
    if (inBox2(uv, gameBlack1_box())) {
        return float4(0.0,0.0,1.0,1.0);
    } else if (inBox2(uv, gameBlack2_box())) {
        return float4(0.0,0.0,1.0,1.0);
    } else if (inBox2(uv, gameGrey1_box())) {
        return float4(0.0,0.0,1.0,1.0);
    }
   
		
	return image.Sample(textureSampler, uv);
	
}

float4 reddify(float4 as)
{
    return (as + float4(1.0,0.0,0.0,1.0))/2.0;
}

float4 renderLevelSelect(float2 uv)
{
    if (inField(uv)) {
        float2 perc = invLerp2(top_left_f(), bot_right_f(), uv);
        if (perc.y < 0.5) {
            float2 adj = float2(uv.x,uv.y);
            adj.x = adj.x - 5.45*blockWidth();
            return image.Sample(textureSampler, adj);
        } else {
            float2 adj = float2(uv.x,uv.y);
            adj.x = adj.x + 3.5*blockWidth();
            adj.y = adj.y - 0.65*blockHeight();
            return image.Sample(textureSampler,adj);
        }
        
    } 
    
    return float4(0.0,0.0,0.0,1.0);
   
}

float4 renderTitle(float2 uv)
{
    if (inField(uv)) {
        float2 perc = invLerp2(top_left_f(), bot_right_f(), uv);
        if (perc.y < 0.2) return float4(0.0,0.0,0.0,1.0);
        
        if (perc.y < 0.7) {
            float2 adj = float2(uv.x,uv.y);
            adj.x = adj.x + 7 *blockWidth();
            adj.y = adj.y + 6 * blockHeight();
            
            if (perc.x >= 0.9) return float4(0.0,0.0,0.0,1.0);
            if (perc.y >= 0.6) return float4(0.0,0.0,0.0,1.0);
            if (perc.x >= 0.8 && perc.y < 0.3) return float4(0.0,0.0,0.0,1.0);
            return image.Sample(textureSampler, adj);
        } else if (perc.y < 0.8){
            float2 adj = float2(uv.x,uv.y);
            adj.x = adj.x - 5.0*blockWidth();
            adj.y = adj.y; //*blockHeight();
            
            return image.Sample(textureSampler,adj);
        } else if (perc.y < 0.845) {
            float2 adj = float2(uv.x,uv.y);
            adj.x = adj.x - 8.0*blockWidth();
            adj.y = adj.y; //*blockHeight();
            if (perc.x > 0.7) return float4(0.0,0.0,0.0,1.0);            
            return image.Sample(textureSampler,adj);
        } else if (perc.y < 0.9) {
            float2 adj = float2(uv.x,uv.y);
            adj.x = adj.x - 2 * blockWidth();
            adj.y = adj.y - 1 * blockHeight();
            if (perc.x < 0.2) return float4(0.0,0.0,0.0,1.0);
            return image.Sample(textureSampler,adj);
        }
        
    } 
    
    return reddify(image.Sample(textureSampler,uv));
}

float4 mainImage(VertData v_in) : TARGET
{	
	float2 uv = v_in.uv;
	float2 pixelSize = pixelUV();
	
	if (setup_mode) {
		return setupDraw(uv);
	} 
	
    float4 r = sampleBlock(gameGrey1_uv(), pixelSize);
    float4 g = sampleBlock(gameBlack2_uv(), pixelSize);
    float4 b = sampleBlock(gameBlack1_uv(), pixelSize);
	
    float4 orig = image.Sample(textureSampler, v_in.uv);
    
    if (isGrey(r) && isBlack(g) && isBlack(b)) //in game
    {
        return image.Sample(textureSampler, v_in.uv);
    } else if (isBlack(r) && isGrey(g) && isGrey(b)) { //title screen
        return renderTitle(uv);        
    } else if (isGrey(r) && isGrey(g) && isBlack(b)) { //level-select
        return renderLevelSelect(uv);
    } else if (isBlack(r) && isBlack(g) && isBlack(b)) { //credits
        //return float4(0.0,0.0,1.0,1.0); //blue
    } else if (isBlue(g) && isBlue(b)) {//rocket         
        //return float4(1.0,1.0,0.0,1.0); //yellow
    } else if (isGrey(r)) { //music
        //return float4(0.0,1.0,1.0,1.0); //teal
    } else { //fallback
        //return image.Sample(textureSampler, v_in.uv);
    }
    
    if (inField(uv)) {       
        return (float4(1.0,1.0,1.0,1.0) + orig) / 2.0;
        
    }
    
    
    return image.Sample(textureSampler, v_in.uv);
	
}
