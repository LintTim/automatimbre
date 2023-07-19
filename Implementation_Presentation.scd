s.options.memSize =  65536;
s.boot;
s.freeAll;
s.quit;

s.meter;
s.plotTree;

(
// editable parameters
var maxWidth = 14, maxHeight = 14; //grid dimensions
var n_synthcells = 7; //must be an odd number
var z = 40; //cell size
var update_time = 0.6; //2.8 for slow demo, duration between grid updates
var iteration_max = 112; //maximum amount of iterations to be executed
var distortion_partials = 0.035; // distortion factor
var volumefactor = 0.15; // to avoid clipping volume regulation of tones played by the 4 groups/clusters
var volume_beats = 0.00; // volume of the heartbeats for making the tempo changes more obvious
var waitingtime_start = 2; // waiting time before iterations start for enhanced visualization of the starting condition
var tempo_var = 0.25; //smaller value more variation in tempo
var population_balance = 11/(maxWidth*maxHeight); // higher value more variation on in lower tempo and vice versa

// horizontal and vertical shift of glider/clock position
//var vshift_g1 = 0;
//var hshift_g1 = 0;
var vshift_g2 = 0;
var hshift_g2 = -11;
var vshift_clock = 9;
var hshift_clock = 1;

// defining fundamental tone of the four groups/clusters
var tone_topleft = 103.826; // G#2/Ab2
var tone_topright = 369.994; // F#4/Gb4
var tone_bottomright = 349.228; // F4
var tone_bottomleft = 261.626; // C4

// fixed variables
var steady_state = false;
var newValues=Array2D.new(maxWidth + 2, maxHeight + 2);
var oldValues=Array2D.new(maxWidth + 2, maxHeight + 2);
var oldOldValues=Array2D.new(maxWidth + 2, maxHeight + 2);
var go, oldneighbor_count, newneighbor_count, leftneighbor_count, rightneighbor_count, adult;
var n_cellcenter = (n_synthcells+1)/2;
var iteration_count = 0;
var population_count = 0;
var refresh_rate = update_time;
//var start completed = false;
var startValues=Array2D.new(maxWidth + 2, maxHeight + 2);
for (1, maxHeight, {arg v;
	for (1, maxWidth, {arg h;
		startValues[h,v] = 0
	});
});
/*
// inital values glider 1
startValues[2+hshift_g1,1+vshift_g1] = 1;
startValues[3+hshift_g1,2+vshift_g1] = 1;
startValues[1+hshift_g1,3+vshift_g1] = 1;
startValues[2+hshift_g1,3+vshift_g1] = 1;
startValues[3+hshift_g1,3+vshift_g1] = 1;
*/
// inital values glider 2
startValues[maxWidth-1+hshift_g2,1+vshift_g2] = 1;
startValues[maxWidth-2+hshift_g2,2+vshift_g2] = 1;
startValues[maxWidth-0+hshift_g2,3+vshift_g2] = 1;
startValues[maxWidth-1+hshift_g2,3+vshift_g2] = 1;
startValues[maxWidth-2+hshift_g2,3+vshift_g2] = 1;
// inital values clock
startValues[2+hshift_clock,1+vshift_clock] = 1;
startValues[2+hshift_clock,2+vshift_clock] = 1;
startValues[4+hshift_clock, 2+vshift_clock] = 1;
startValues[1+hshift_clock,3+vshift_clock] = 1;
startValues[3+hshift_clock,3+vshift_clock] = 1;
startValues[3+hshift_clock,4+vshift_clock] = 1;

// Definition of the synths
SynthDef.new(\synthgroup_top_left,{
	arg pos_h=n_cellcenter, pos_v=n_cellcenter, dist=distortion_partials, n_neighbors=4, adult=0, refreshrate=refresh_rate, n_left=0, n_right=0;
	var sig, env, freq, freq_p2, freq_p3, freq_p4, freq_p5, freq_p6, freq_p7, freq_p8, freq_p9, amp_p2, amp_p3, amp_p4, amp_p5, amp_p6, amp_p7, amp_p8, amp_p9, space;
	var delay, acceleration, duration, decay, spread=1, level, center;
	delay = (adult * refreshrate/4) + (n_neighbors * refreshrate/7);
	acceleration = ((1+adult)*refreshrate/9) - (n_neighbors*refreshrate/36) ;
	duration = refreshrate/5 + (adult * refreshrate/6) + ((3-n_neighbors) * refreshrate/8);
	decay = (3*refreshrate/(1+n_neighbors)) + ((2-adult)*refreshrate/2);
	env = EnvGen.kr(Env.new([0,0,1,0.95,0], [delay, acceleration, duration, decay], [0,4,-2,0]), doneAction:2);
	space = 0.9 - (n_neighbors * 0.1);
	amp_p2 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p3 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p4 = 0.5*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p5 = 0.4*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p6 = 0.25*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p7 = 0.2*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p8 = 0.15*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p9 = 0.1*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	freq=tone_topleft;
	freq_p2 = (dist*(pos_h - n_cellcenter)*freq) + (2*freq);
	freq_p3 = (dist*(pos_h - n_cellcenter)*freq) + (3*freq);
	freq_p4 = 4*freq;
	freq_p5 = 5*freq;
	freq_p6 = 6*freq;
	freq_p7 = 7*freq;
	freq_p8 = 8*freq;
	freq_p9 = 9*freq;
	sig = volumefactor/(n_synthcells) * ( (SinOsc.ar(freq_p2)*amp_p2) + (SinOsc.ar(freq_p3)*amp_p3) + (SinOsc.ar(freq_p4)*amp_p4) + (SinOsc.ar(freq_p5)*amp_p5) + (SinOsc.ar(freq_p6)*amp_p6) + (SinOsc.ar(freq_p7)*amp_p7) + (SinOsc.ar(freq_p8)*amp_p8) + (SinOsc.ar(freq_p9)*amp_p9) ) * env;
	sig = FreeVerb.ar(sig, 0.4, space, (1/space));
	level = 0.9**(8-n_neighbors);
	center = (0.5**n_right) - (0.5**n_left);
	Out.ar(0, Splay.ar(sig, spread, level, center));
}).add;

SynthDef.new(\synthgroup_top_right,{
	arg pos_h=(n_cellcenter+n_synthcells), pos_v=n_cellcenter, dist=distortion_partials, n_neighbors=4, adult=0, refreshrate=refresh_rate, n_left=0, n_right=0;
	var sig, env, freq, freq_p2, freq_p3, freq_p4, freq_p5, freq_p6, freq_p7, freq_p8, freq_p9, amp_p2, amp_p3, amp_p4, amp_p5, amp_p6, amp_p7, amp_p8, amp_p9, space;
	var delay, acceleration, duration, decay, spread=1, level, center;
	delay = (adult * refreshrate/4) + (n_neighbors * refreshrate/7);
	acceleration = ((1+adult)*refreshrate/9) - (n_neighbors*refreshrate/36) + refreshrate/25 ;
	duration = refreshrate/5 + (adult * refreshrate/6) + ((3-n_neighbors) * refreshrate/8);
	decay = (3*refreshrate/(1+n_neighbors)) + ((2-adult)*refreshrate/2);
	env = EnvGen.kr(Env.new([0,0,1,0.95,0], [delay, acceleration, duration, decay], [0,4,-2,0]), doneAction:2);
	space = 0.9 - (n_neighbors * 0.1);
	amp_p2 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p3 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p4 = 0.5*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p5 = 0.4*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p6 = 0.25*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p7 = 0.2*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p8 = 0.15*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p9 = 0.1*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	freq=tone_topright;
	freq_p2 = (dist*(pos_h - n_cellcenter - n_synthcells)*freq) + (2*freq);
	freq_p3 = (dist*(pos_h - n_cellcenter)*freq) + (3*freq);
	freq_p4 = 4*freq;
	freq_p5 = 5*freq;
	freq_p6 = 6*freq;
	freq_p7 = 7*freq;
	freq_p8 = 8*freq;
	freq_p9 = 9*freq;
	sig = volumefactor/(n_synthcells) * ( (SinOsc.ar(freq_p2)*amp_p2) + (SinOsc.ar(freq_p3)*amp_p3) + (SinOsc.ar(freq_p4)*amp_p4) + (SinOsc.ar(freq_p5)*amp_p5) + (SinOsc.ar(freq_p6)*amp_p6) + (SinOsc.ar(freq_p7)*amp_p7) + (SinOsc.ar(freq_p8)*amp_p8) + (SinOsc.ar(freq_p9)*amp_p9) ) * env;
	sig = FreeVerb.ar(sig, 0.4, space, (1/space));
	level = 0.9**(8-n_neighbors);
	center = (0.5**n_right) - (0.5**n_left);
	Out.ar(0, Splay.ar(sig, spread, level, center));
}).add;

SynthDef.new(\synthgroup_bottom_right,{
	arg pos_h=n_cellcenter, pos_v=(n_cellcenter+n_synthcells), dist=distortion_partials, n_neighbors=4, adult=0, refreshrate=refresh_rate, n_left=0, n_right=0;
	var sig, env, freq, freq_p2, freq_p3, freq_p4, freq_p5, freq_p6, freq_p7, freq_p8, freq_p9, amp_p2, amp_p3, amp_p4, amp_p5, amp_p6, amp_p7, amp_p8, amp_p9, space;
	var delay, acceleration, duration, decay, spread=1, level, center;
	delay = (adult * refreshrate/4) + (n_neighbors * refreshrate/7);
	acceleration = ((1+adult)*refreshrate/9) - (n_neighbors*refreshrate/36) ;
	duration = refreshrate/5 + (adult * refreshrate/6) + ((3-n_neighbors) * refreshrate/8);
	decay = (3*refreshrate/(1+n_neighbors)) + ((2-adult)*refreshrate/2);
	env = EnvGen.kr(Env.new([0,0,1,0.95,0], [delay, acceleration, duration, decay], [0,4,-2,0]), doneAction:2);
	space = 0.9 - (n_neighbors * 0.1);
	amp_p2 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p3 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p4 = 0.5*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p5 = 0.4*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p6 = 0.25*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p7 = 0.2*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p8 = 0.15*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p9 = 0.1*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	freq=tone_bottomright;
	freq_p2 = (dist*(pos_h - n_cellcenter)*freq) + (2*freq);
	freq_p3 = (dist*(pos_h - n_cellcenter - n_synthcells)*freq) + (3*freq);
	freq_p4 = 4*freq;
	freq_p5 = 5*freq;
	freq_p6 = 6*freq;
	freq_p7 = 7*freq;
	freq_p8 = 8*freq;
	freq_p9 = 9*freq;
	sig = volumefactor/(n_synthcells) * ( (SinOsc.ar(freq_p2)*amp_p2) + (SinOsc.ar(freq_p3)*amp_p3) + (SinOsc.ar(freq_p4)*amp_p4) + (SinOsc.ar(freq_p5)*amp_p5) + (SinOsc.ar(freq_p6)*amp_p6) + (SinOsc.ar(freq_p7)*amp_p7) + (SinOsc.ar(freq_p8)*amp_p8) + (SinOsc.ar(freq_p9)*amp_p9) ) * env;
	sig = FreeVerb.ar(sig, 0.4, space, (1/space));
	level = 0.9**(8-n_neighbors);
	center = (0.5**n_right) - (0.5**n_left);
	Out.ar(0, Splay.ar(sig, spread, level, center));
}).add;

SynthDef.new(\synthgroup_bottom_left,{
	arg pos_h=(n_cellcenter+n_synthcells), pos_v=(n_cellcenter+n_synthcells), dist=distortion_partials, n_neighbors=4, adult=0, refreshrate=refresh_rate, n_left=0, n_right=0;
	var sig, env, freq, freq_p2, freq_p3, freq_p4, freq_p5, freq_p6, freq_p7, freq_p8, freq_p9, amp_p2, amp_p3, amp_p4, amp_p5, amp_p6, amp_p7, amp_p8, amp_p9, space;
	var delay, acceleration, duration, decay, spread=1, level, center;
	delay = (adult * refreshrate/4) + (n_neighbors * refreshrate/7);
	acceleration = ((1+adult)*refreshrate/9) - (n_neighbors*refreshrate/36) ;
	duration = refreshrate/5 + (adult * refreshrate/6) + ((3-n_neighbors) * refreshrate/8);
	decay = (3*refreshrate/(1+n_neighbors)) + ((2-adult)*refreshrate/2);
	env = EnvGen.kr(Env.new([0,0,1,0.95,0], [delay, acceleration, duration, decay], [0,4,-2,0]), doneAction:2);
	space = 0.9 - (n_neighbors * 0.1);
	amp_p2 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p3 = LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p4 = 0.5*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p5 = 0.4*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p6 = 0.25*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p7 = 0.2*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p8 = 0.15*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	amp_p9 = 0.1*LFNoise0.kr(exprand(4,16)).range(0.95,1);
	freq=tone_bottomleft;
	freq_p2 = (dist*(pos_h - n_cellcenter - n_synthcells)*freq) + (2*freq);
	freq_p3 = (dist*(pos_h - n_cellcenter - n_synthcells)*freq) + (3*freq);
	freq_p4 = 4*freq;
	freq_p5 = 5*freq;
	freq_p6 = 6*freq;
	freq_p7 = 7*freq;
	freq_p8 = 8*freq;
	freq_p9 = 9*freq;
	sig = volumefactor/(n_synthcells) * ( (SinOsc.ar(freq_p2)*amp_p2) + (SinOsc.ar(freq_p3)*amp_p3) + (SinOsc.ar(freq_p4)*amp_p4) + (SinOsc.ar(freq_p5)*amp_p5) + (SinOsc.ar(freq_p6)*amp_p6) + (SinOsc.ar(freq_p7)*amp_p7) + (SinOsc.ar(freq_p8)*amp_p8) + (SinOsc.ar(freq_p9)*amp_p9) ) * env;
	sig = FreeVerb.ar(sig, 0.4, space, (1/space));
	level = 0.9**(8-n_neighbors);
	center = (0.5**n_right) - (0.5**n_left);
	Out.ar(0, Splay.ar(sig, spread, level, center));
}).add;

SynthDef.new(\synth_beat_A1,{
	arg freq=55, refreshrate=refresh_rate;
	var env, sig, amp;
	amp=volume_beats;
	//Env.new([0,0,1,0,0],[1/3, 1/12,1/12, 1/2]).plot;
	env = EnvGen.kr(Env.new([0, 0, 1, 0, 0],[refreshrate/3, refreshrate/12,refreshrate/12, refreshrate/2]), doneAction:2);
	sig = amp * env * SinOsc.ar(freq);
	Out.ar(0, sig);
}).add;

SynthDef.new(\synth_beat_A1sharp,{
	arg freq=58.2705, refreshrate=refresh_rate;
	var env, sig, amp;
	amp=volume_beats;
	//Env.new([0,0,1,0,0],[1/6, 1/12,1/12, 2/3]).plot;
	env = EnvGen.kr(Env.new([0, 0, 1, 0, 0],[refreshrate/6, refreshrate/12,refreshrate/12, 2*refreshrate/3]), doneAction:2);
	sig = amp * env * SinOsc.ar(freq);
	Out.ar(1, sig);
}).add;


// window setup
w=Window("Game of Life", Rect(15, 15, z*(maxWidth+2), z*(maxHeight+2))).front;
w.view.background_(Color.white);
w.front;

// drawing function determining cell colors based on their values
w.drawFunc = {
		for (1, maxHeight, {arg v;
			for (1, maxWidth, {arg h;
				if (newValues[h,v]==0,
					{Pen.fillColor=Color.gray},
					{Pen.fillColor=Color.green}
				);
				Pen.addRect(Rect(h*z, v*z, z, z));
				Pen.fill;
			});
		});
};

go=Routine({
	// generate initial pattern
	for (1, maxWidth, {arg h;
		for (1, maxHeight, {arg v;
			//newValues[h,v]=[0, 1].choose; //random pattern
			newValues[h,v]=startValues[h,v]; //defined pattern
			//{w.refresh}.defer;
		})
	});
	waitingtime_start.wait;

	//update cycle
	while ({steady_state==false},{
		//waiting time in between cycles
		refresh_rate.wait;
		population_count = 0; //set population count to zero again

		/*
		// play beats
		b = Synth.new(\synth_beat_A1, [\refreshrate, refresh_rate]);
		b = Synth.new(\synth_beat_A1sharp, [\refreshrate, refresh_rate]);
		*/

		//copy edges of board to edges of array
		for(1, maxWidth, {arg h;
			newValues[h,0]=newValues[h, maxHeight];
			newValues[h, maxHeight+1]=newValues[h, 1];
		});
		for(1, maxHeight, {arg v;
			newValues[ 0, v]=newValues[maxWidth, v];
			newValues[maxWidth+1, v]=newValues[1, v];
		});
		newValues[0,0]=newValues[maxWidth, maxHeight];
		newValues[0, maxHeight+1]=newValues[maxWidth, 1];
		newValues[maxWidth+1, 0]=newValues[1, maxHeight];
		newValues[maxWidth+1, maxHeight+1]=newValues[1,1];

		//overwrite old cell values with new cell values
		for (0, maxWidth+1, {arg h;
			for (0, maxHeight+1, {arg v;
				oldOldValues[h,v] = oldValues[h,v];
				oldValues[h,v] = newValues[h,v];
			})
		});

		//calculation of new cell values based on old cell values
		for (1, maxWidth,{arg h;
			for (1, maxHeight, {arg v;
				oldneighbor_count = oldValues[h-1,v-1]+oldValues[h,v-1]+oldValues[h+1,v-1]+oldValues[h-1,v]+oldValues[h+1,v]+oldValues[h-1,v+1]+oldValues[h,v+1]+oldValues[h+1,v+1];
					if(
					(oldneighbor_count <= 1), //death due to underpopulation
					{newValues[h,v] = 0}
				);
				if(
					(oldneighbor_count > 3), //death due to overpopulation
					{newValues[h,v] = 0}
				);
				if(
					oldneighbor_count == 3, //birth and survival with 3 neighbors
					{newValues[h,v] = 1}
				);
				if(
					oldneighbor_count == 2, //survival with 2 neighbors, when already alive
					{newValues[h,v] = oldValues[h,v]}
				);
				{w.refresh}.defer; //refresh window accordingly
			})
		});

		//calculation tempo based on new population
		for (1, maxWidth,{arg h;
			for (1, maxHeight, {arg v;
				if (newValues[h,v]==1,{
					population_count = (population_count+1);
				});
			})
		});
		refresh_rate = update_time * (1/tempo_var**(5*(population_balance-(population_count/(maxWidth*maxHeight))))); //determine new duration (thus tempo) based on relative population

		//sound gen based on new cell values
		for (1, maxWidth,{arg h;
			for (1, maxHeight, {arg v;
				if (newValues[h,v]==1,{
					//population_count = (population_count+1);
					leftneighbor_count = newValues[h-1,v-1] + newValues[h-1,v] + newValues[h-1,v+1];
					rightneighbor_count = newValues[h+1,v-1] + newValues[h+1,v] + newValues[h+1,v+1];
					newneighbor_count = leftneighbor_count + rightneighbor_count + newValues[h,v+1] + newValues[h,v-1];
					if (newValues[h,v]==oldValues[h,v],
						{adult = 1},
						{adult = 0}
					);
					if (h <= n_synthcells,
						{
							if(v <= n_synthcells,
								{
									x = Synth.new(\synthgroup_top_left, [\pos_v,v, \pos_h,h, \n_neighbors,newneighbor_count, \adult,adult, \refreshrate,refresh_rate, \n_left,leftneighbor_count, \n_right,rightneighbor_count])
								},
								{
									x = Synth.new(\synthgroup_bottom_left, [\pos_v,v, \pos_h,h, \n_neighbors,newneighbor_count, \adult,adult, \refreshrate,refresh_rate, \n_left,leftneighbor_count, \n_right,rightneighbor_count])
								}
							);
						},
						{
							if(v <= n_synthcells,
								{
									x = Synth.new(\synthgroup_top_right, [\pos_v,v, \pos_h,h, \n_neighbors,newneighbor_count, \adult,adult, \refreshrate,refresh_rate, \n_left,leftneighbor_count, \n_right,rightneighbor_count])
								},
								{
									x = Synth.new(\synthgroup_bottom_right, [\pos_v,v, \pos_h,h, \n_neighbors,newneighbor_count, \adult,adult, \refreshrate,refresh_rate, \n_left,leftneighbor_count, \n_right,rightneighbor_count])
								}
							);
						}
					);
				});
			})
		});

		//check if a steady-state has been reached
		steady_state = true;
		for (1, maxWidth,{arg h;
			for (1, maxHeight, {arg v;
				if (oldValues[h,v] != newValues[h,v],
					{steady_state = false},
					{
						if (oldOldValues[h,v] != newValues[h,v],
							{steady_state = false}
						);
					}
				);
			})
		});

		//check if maximum amount of iterations executed
		iteration_count = (iteration_count+1);
		if(
			iteration_count>(iteration_max-1),
			{steady_state = true}
		);

		//post number of executed iterations
		iteration_count.postln;

	});
});

go.play;
)