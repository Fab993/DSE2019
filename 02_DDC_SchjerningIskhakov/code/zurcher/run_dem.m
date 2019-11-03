clear; close all;
global ev0;  ev0=0;

%% NFXP options
ap=solve.setup;

% Read default parameters in to struct mp 
mp=zurcher.setup;
mp.integrated=1;

for dynamic=0:1;
	if dynamic
		% Estimated parameters, dynamic model
		mp.RC=10.0750;
		mp.c=2.2930;
		mp.p=[0.3919 0.5953 ]';
		mp.beta=0.9999;					
		pl='-b';				
	else
		% Estimated parameters, static model
		mp.RC=7.6358;
		mp.c=71.5133;
		mp.p=[0.3919 0.5953 ]'	
		mp.beta=0;
		pl='-r';				
	end

	P = zurcher.statetransition(mp);	% Transition matrix for mileage

	% belman equation
	bellman= @(ev) zurcher.bellman(ev, mp, P);

	% solve using poly algorith (use combination of SA and NK)
	[ev0, pk]=solve.poly(bellman, ev0, ap, mp.beta);	

%	[ev0, pk]=nfxp.solve(ev0, P, cost, mp, nfxp_options); 	% Solve the model
	[pp, pp_K, pp_R] = zurcher.eqb(mp,P, pk); 

	x=mp.max*1000*(1:mp.n)'; 
	fprintf('Fraction of bus engines replaced each month : %1.5f \n', sum(pp_R'));
	fprintf('Mean lifetime of bus engine (months)        : %1.5f \n', 1/sum(pp_R'));
	fprintf('Mean mileage at overhaul                    : %1.5f \n',  sum(x.*pp_R')/(mp.n*sum(pp_R')));
	fprintf('Mean mileage since last Replacement         : %1.5f \n',  sum(x.*pp_K')/(mp.n*sum(pp_K')));

	figure(1)
	plot(mp.grid, [pp_K' 100*pp_R']);
	legend('Pr(x, i=Keep)', 'Pr(x, i=Replace)')
	title('Equilibrium Distribution: Bus mileage');
	xlabel('Mileage');
	ylabel('CDF'); 

    % Now compute the expected demand for bus engines over a fixed interval of time
    % as a function of the price of new bus engines, mp.RC. The estimated demand function depends 
    % on the discount factor, mp.beta and the parameters of the cost function, mp.c 
    % The program also computes expected mileage at overhaul 
    % as a function of mp.RC. In fact, the program computes the entire equilibrium distribution 
    % for (x,i) as a function of RC, so that it is possible to trace out how the entire distribution of 
    % demand for bus engines shifts as a function of mp.RC

    mp0=mp; % save mp before varying mp.RC
	RCgrid=1:0.5:30;
	for i=1:numel(RCgrid);
		mp.RC=RCgrid(i);
		% belman equation
		bellman= @(ev) zurcher.bellman(ev, mp, P);

		[ev0, pk]=solve.poly(bellman, ev0, ap, mp.beta);	% solve model using poly algorith 
		[pp, pp_K, pp_R] = zurcher.eqb(mp,P, pk);   		% compute equilibrium distribution
		Demand(i)=12*sum(pp_R');			% Demand: Expected number of bus engines replaced in equilibrium
	end

	figure(2)
	hold on;
	plot(RCgrid*7513/mp0.RC, Demand, pl);
	ylim([0 1])
	xlim([0 12000])
	title('Expected Replacement Demand Function');
	xlabel('Replacement cost, RC');
	ylabel('Expected Annual Engine Replacement'); 
	legend('beta==0', 'beta=0.9999')
end
