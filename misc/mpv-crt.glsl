//!HOOK OUTPUT
//!BIND HOOKED
//!DESC CRT_EMU

#define PI 3.14159265359

#define IN_GAIN 1.00				//input signal gain

#define SCANLINE_STR 1.0	       //scanlines strength
#define SCANLINE_FREQUENCY 1/2.0   //Scanline frequency multiplier
#define SCANLINE_MIN_SIZE 0.2	   //Min scanlines height
#define SCANLINE_MAX_SIZE 0.9      //Max scanlines height

#define RGBMASK_STR 1.0	         //RGB mask strength
#define RGBMASK_FREQUENCY 1/1.0  //RGB mask frequency

#define ADD_POWER 1.5           //Extra brightness power
#define ADD_GAMMA 2.34			//Extra brightness input treshold
#define ADD_ON_SCANLINE 0.5     //Extra brightness on scanlines gaps mix

#define TEMPERATURE 7200        //Output color temperature

#define IN_GAMMA 2.2
#define OUT_GAMMA 0.4

vec3 kelvin2rgb(float k) {
	//Convert kelvin temperature to rgb factors
	k = clamp(k,1000,40000);
	k=k/100.0;
	float tmpCalc;
	vec3 t_out;
	if (k<=66) {
		t_out.r = 255;
		t_out.g = 99.47080258612 * log(k) - 161.11956816610;
	} else {
		t_out.r = 329.6987274461 * pow(k - 60 ,-0.13320475922);
		t_out.g = 288.12216952833 * pow(k-60, -0.07551484921);
	}

	if (k >= 66)
		t_out.b = 255;
	else if (k<=19)
		t_out.b = 0;
	else
		t_out.b = 138.51773122311 * log(k - 10) - 305.04479273072;

	return t_out/255.0;
}

vec3 morph_shape(vec3 shape, vec3 l,float gamma ) {    
    vec3 l_pow = pow(l,vec3(gamma));
    vec3 l2 = min(l_pow * 16, 1.0);
    vec3 s1 = pow(shape, inversesqrt(l2));
    vec3 s2 = fma(-l_pow, s1,  l_pow); //ASM PROOF, faster.
    return s2 + s1;
}


vec3 scanlines(vec3 c){	
    //float freq_y = HOOKED_pos.y * input_size.y * PI  * SCANLINE_FREQUENCY;
	float freq_y = floor(HOOKED_pos.y * target_size.y)  * PI * 0.5 * SCANLINE_FREQUENCY;
	vec3 rgbh = vec3(sin(freq_y));
	rgbh*=rgbh;
	vec3 min_in  = vec3(0.0);
	vec3 max_in  = vec3(IN_GAIN);
	vec3 min_out = vec3(SCANLINE_MIN_SIZE);
	vec3 max_out = vec3(SCANLINE_MAX_SIZE);
	c = min_out + (c - min_in) * (max_out - min_out) / (max_in - min_in);
	//c = min_out + c * ( vec3(1.0) - min_out);
	rgbh = morph_shape(rgbh, c, 4.2);
	return rgbh;
}


vec3 rgbmask(vec3 c){	
	vec3 rgboffsets = vec3(0.0,1.0,2.0)/3.0;	
	vec3 freq_rgb = vec3 ( target_size.x * RGBMASK_FREQUENCY * HOOKED_pos.x * PI * 2.0/3.0 + PI - (rgboffsets * 2 * PI) );
	vec3 rgbw = (1 + cos(freq_rgb.rgb)) * 0.5;
	vec3 min_out = vec3(0.3);
	c = min_out + c * ( vec3(1.0) - min_out);
	rgbw = morph_shape(rgbw, c, 4.2);
	return rgbw;
}

vec4 hook(){
	vec3 c = HOOKED_texOff(0).rgb;    
	
	c*=IN_GAIN;
	c=pow(c, vec3(IN_GAMMA));
	
	vec3 add = pow(c/IN_GAIN,vec3(ADD_GAMMA))*ADD_POWER;
	
	vec3 rgbh = mix(vec3(1.0), scanlines(c.rgb), vec3(SCANLINE_STR));
	vec3 rgbw = mix(vec3(1.0), rgbmask(c.rgb)  , vec3(RGBMASK_STR));
	vec3 mask = rgbh*rgbw;
	vec3 cout = c*mask;
	
	cout+=mix(add * ADD_ON_SCANLINE, add, rgbh);
	
	cout = pow(cout, vec3(OUT_GAMMA));
	
	cout *= kelvin2rgb(TEMPERATURE);
	
	return vec4(cout, 1.0);

}
