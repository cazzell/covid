clear
close all
clc
colorbuild

% Figure out day of first positive test.
% Set that to day = 0. Only plot that data.
% Normalize by state population
% populationImport = webread('https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/state/detail/SCPRC-EST2019-18+POP-RES.csv')

popDataFull = webread('https://odn.data.socrata.com/resource/tx2x-uhib.json');
year_str = '2010';
year_index = find(strcmp({popDataFull.year}, year_str));
popData = popDataFull(year_index);

state_str = 'state';
state_index = find(strcmp({popData.type}, state_str));
popData = popData(state_index);

state_abrv_full_download = {'AK';'AL';'AR';'AS';'AZ';'CA';'CO';'CT';'DC';'DE';'FL';'GA';'GU';'HI';'IA';'ID';'IL';'IN';'KS';'KY';'LA';'MA';'MD';'ME';'MI';'MN';'MO';'MP';'MS';'MT';'NC';'ND';'NE';'NH';'NJ';'NM';'NV';'NY';'OH';'OK';'OR';'PA';'PR';'RI';'SC';'SD';'TN';'TX';'UT';'VA';'VI';'VT';'WA';'WI';'WV';'WY'};

%web_import_states = webread('https://covidtracking.com/api/states/daily');
web_import_states_raw = webread('https://covidtracking.com/api/states/daily');
%web_import_states = webread('https://covidtracking.com/api/v1/states/daily.json');

web_import_us_raw = webread('https://covidtracking.com/api/us/daily');

% From https://github.com/pomber/covid19 which is from John Hopkins
web_import_raw_nations = webread('https://pomber.github.io/covid19/timeseries.json');

% From ecdc
web_import_raw_nation_ecdc = webread('https://opendata.ecdc.europa.eu/covid19/casedistribution/json/');

% On 4/2 the API seemingly changed. So need to fill in missing gaps
% Look at all of the field names
max_fields = 1;
max_field_index = 1;

for structNum = 1:length(web_import_states_raw)

	field_names{structNum,1} = fieldnames(web_import_states_raw{structNum});
	current_field_num = length(field_names{structNum,1});
	
	if current_field_num > max_fields
		max_fields = current_field_num;
		max_field_index = structNum;
	end
end

master_field_names = field_names{max_field_index,1};

for structNum = 1:length(web_import_states_raw)

	%field_names{structNum,1} = fieldnames(web_import_states_raw{structNum});
	current_field_num = length(field_names{structNum,1});
	
	if current_field_num < max_fields
		for field_index = 1:max_fields
			current_field = master_field_names{field_index};
			if ~ismember(current_field, field_names{structNum,1})
				web_import_states_raw{structNum,1}.(current_field) = [];
			end
		end
	end
end

for structNum = 1:length(web_import_states_raw)
	
	web_import_states(structNum) = web_import_states_raw{structNum}
	
end

state_abrv = {'AK';'AL';'AR';'AZ';'CA';'CO';'CT';'DC';'DE';'FL';'GA';'HI';'IA';'ID';'IL';'IN';'KS';'KY';'LA';'MA';'MD';'ME';'MI';'MN';'MO';'MS';'MT';'NC';'ND';'NE';'NH';'NJ';'NM';'NV';'NY';'OH';'OK';'OR';'PA';'PR';'RI';'SC';'SD';'TN';'TX';'UT';'VA';'VT';'WA';'WI';'WV';'WY'};
state_names = {'Alaska';'Alabama';'Arkansas';'Arizona';'California';'Colorado';'Connecticut';'District of Columbia';'Delaware';'Florida';'Georgia';'Hawaii';'Iowa';'Idaho';'Illinois';'Indiana';'Kansas';'Kentucky';'Louisiana';'Massachusetts';'Maryland';'Maine';'Michigan';'Minnesota';'Missouri';'Mississippi';'Montana';'North Carolina';'North Dakota';'Nebraska';'New Hampshire';'New Jersey';'New Mexico';'Nevada';'New York';'Ohio';'Oklahoma';'Oregon';'Pennsylvania';'Puerto Rico';'Rhode Island';'South Carolina';'South Dakota';'Tennessee';'Texas';'Utah';'Virginia';'Vermont';'Washington';'Wisconsin';'West Virginia';'Wyoming'};

list_of_states = {web_import_states.state};

for current_state_num = 1:length(state_abrv)
	current_state_str = state_abrv{current_state_num};
	current_index = find(strcmp(list_of_states, current_state_str));
	state_data.(current_state_str) = web_import_states(current_index);
	
	% Days since first positive cases
	current_dates = datetime([state_data.(current_state_str).date], 'ConvertFrom', 'yyyymmdd');
	len_state = length([state_data.(current_state_str).positive]);
 	posarray = ([state_data.(current_state_str).positive] > 0);
 	pos_days = sum(posarray);
 	day_vector = zeros(len_state,1);
 	days = flip([1:pos_days]);
 	day_vector(1:pos_days) = days;
	
	for state_data_index = 1:len_state
		state_data.(current_state_str)(state_data_index).positiveDays = day_vector(state_data_index);
	end
	
	% Doubling Time
	for currentDoubleDay = 1:pos_days-1
		q_1 = state_data.(current_state_str)(currentDoubleDay).positive;
		q_2 = state_data.(current_state_str)(currentDoubleDay+1).positive;
		state_data.(current_state_str)(currentDoubleDay).currentDoubleRate = log(2) ./ (log(q_1./q_2));
	end
	
	for currentDoubleDay = 1:pos_days-3
		q_1 = state_data.(current_state_str)(currentDoubleDay).positive;
		q_2 = state_data.(current_state_str)(currentDoubleDay+3).positive;
		state_data.(current_state_str)(currentDoubleDay).currentDoubleRate_three = 3.* (log(2) ./ (log(q_1./q_2)));
	end
	

	rawDouble = [state_data.(current_state_str)(1:state_data.(current_state_str)(1).positiveDays).currentDoubleRate];
	medDoubleThree = movmedian(rawDouble,3);
	for currentDoubleDay = 1:pos_days-1
		q_1 = state_data.(current_state_str)(currentDoubleDay).positive;
		q_2 = state_data.(current_state_str)(currentDoubleDay+1).positive;
		state_data.(current_state_str)(currentDoubleDay).medDoubleThree = medDoubleThree(currentDoubleDay);
	end
	
	
	% Population Data
	state_str = state_names{current_state_num};
	popIndex = find(strcmp({popData.name}, state_str));
	population = popData(popIndex).population;
	
	state_data.(current_state_str)(1).population = str2num(population);
	
end

% figure
% hold on
% plot([state_data.MA.date], [state_data.MA.positive],'Color', color1)
% plot([state_data.NY.date], [state_data.NY.positive],'Color', color2)
% plot([state_data.OH.date], [state_data.OH.positive],'Color', color3)
% set(gca,'yscale','log')
% %set(gca,'xscale','log')
% axis square
% box on
% 
% plot_state_1 = 'MA';
% plot_state_2 = 'NY';
% 
% figure
% hold on
% plot([state_data.(plot_state_1).date], [state_data.(plot_state_1).positive],'-','Color', color1)
% plot([state_data.(plot_state_1).date], [state_data.(plot_state_1).totalTestResults],'--','Color', color1)
% plot([state_data.(plot_state_2).date], [state_data.(plot_state_2).positive],'-','Color', color2)
% plot([state_data.(plot_state_2).date], [state_data.(plot_state_2).totalTestResults],'--','Color', color2)
% set(gca,'yscale','log')
% %set(gca,'xscale','log')
% axis square
% box on
% 
% plot_state_1 = 'MA';
% plot_state_2 = 'OH';
% plot_state_3 = 'NY';
% plot_state_4 = 'WA';
% figure
% hold on
% plot([state_data.(plot_state_1).date], [state_data.(plot_state_1).positive],'-','Color', color1)
% plot([state_data.(plot_state_1).date], [state_data.(plot_state_1).totalTestResults],'--','Color', color1)
% plot([state_data.(plot_state_2).date], [state_data.(plot_state_2).positive],'-','Color', color2)
% plot([state_data.(plot_state_2).date], [state_data.(plot_state_2).totalTestResults],'--','Color', color2)
% plot([state_data.(plot_state_3).date], [state_data.(plot_state_3).positive],'-','Color', color3)
% plot([state_data.(plot_state_3).date], [state_data.(plot_state_3).totalTestResults],'--','Color', color3)
% plot([state_data.(plot_state_4).date], [state_data.(plot_state_4).positive],'-','Color', color4)
% plot([state_data.(plot_state_4).date], [state_data.(plot_state_4).totalTestResults],'--','Color', color4)
% set(gca,'yscale','log')
% %set(gca,'xscale','log')
% axis square
% box on
% 
% 
% plot_state_1 = 'OH';
% plot_state_2 = 'NY';
% plot_state_3 = 'CA';
% plot_state_4 = 'WA';
% figure
% hold on
% %fill([[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays])],[[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults])],color1,'FaceAlpha', 0.5)
% %fill([[state_data.(plot_state_2).date], flip([state_data.(plot_state_2).date])],[[state_data.(plot_state_2).positive], flip([state_data.(plot_state_2).totalTestResults])],color2,'FaceAlpha', 0.5)
% %fill([[state_data.(plot_state_3).date], flip([state_data.(plot_state_3).date])],[[state_data.(plot_state_3).positive], flip([state_data.(plot_state_3).totalTestResults])],color3,'FaceAlpha', 0.5)
% %fill([[state_data.(plot_state_4).date], flip([state_data.(plot_state_4).date])],[[state_data.(plot_state_4).positive], flip([state_data.(plot_state_4).totalTestResults])],color4,'FaceAlpha', 0.5)
% set(gca,'yscale','log')
% %set(gca,'xscale','log')
% axis square
% box on
% 
% 
% 
% plot_state_1 = 'MA';
% plot_state_2 = 'OH';
% plot_state_3 = 'NY';
% plot_state_4 = 'WA';
% figure
% hold on
% fill([[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays])],[[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults])],color1,'FaceAlpha', 0.25,'EdgeColor', color1)
% fill([[state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays], flip([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays])],[[state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positive], flip([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).totalTestResults])],color2,'FaceAlpha', 0.25,'EdgeColor', color2)
% fill([[state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays], flip([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays])],[[state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positive], flip([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).totalTestResults])],color3,'FaceAlpha', 0.25,'EdgeColor', color3)
% fill([[state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays], flip([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays])],[[state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positive], flip([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).totalTestResults])],color4,'FaceAlpha', 0.25,'EdgeColor', color4)
% %plot(linspace(1,30,100),1.2.^linspace(1,30,100))
% %plot(linspace(1,30,100),1.4.^linspace(1,30,100))
% %plot(linspace(1,30,100),1.6.^linspace(1,30,100))
% %plot(linspace(1,30,100),1.8.^linspace(1,30,100))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/1))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/2))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/3))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/4))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/5))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/6))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/7))
% %fill([[state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays], flip([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays])],[[state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positive], flip([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).totalTestResults])],color4,'FaceAlpha', 0.5)
% set(gca,'yscale','log')
% %set(gca,'xscale','log')
% axis([0,30,1,10^6])
% legend(plot_state_1, plot_state_2, plot_state_3, plot_state_4)
% xlabel('Days Since First Positive') 
% ylabel('Number of Positives and Total Tests') 
% axis square
% box on
% saveas(gcf,'plot.eps','epsc')



% My plot

plot_state_1 = 'MA';
plot_state_2 = 'OH';
plot_state_3 = 'NY';
plot_state_4 = 'TN';

figure
hold on

fill([[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays])],    100.*([[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults])])./ (state_data.(plot_state_1)(1).population), color1,'FaceAlpha', 0.25,'EdgeColor', color1)
fill([[state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays], flip([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays])],    100.*([[state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positive], flip([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).totalTestResults])])./ (state_data.(plot_state_2)(1).population), color2,'FaceAlpha', 0.25,'EdgeColor', color2)
fill([[state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays], flip([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays])],    100.*([[state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positive], flip([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).totalTestResults])])./ (state_data.(plot_state_3)(1).population), color3,'FaceAlpha', 0.25,'EdgeColor', color3)
fill([[state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays], flip([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays])],    100.*([[state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positive], flip([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).totalTestResults])])./ (state_data.(plot_state_4)(1).population), color4,'FaceAlpha', 0.25,'EdgeColor', color4)

plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive])./ (state_data.(plot_state_1)(1).population),'-o','Color',color1,'MarkerFaceColor',color1)
plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults])./ (state_data.(plot_state_1)(1).population),'-o','Color',color1)

plot([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positive])./ (state_data.(plot_state_2)(1).population),'-s','Color',color2,'MarkerFaceColor',color2)
plot([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).totalTestResults])./ (state_data.(plot_state_2)(1).population),'-s','Color',color2)

plot([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positive])./ (state_data.(plot_state_3)(1).population),'-d','Color',color3,'MarkerFaceColor',color3)
plot([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).totalTestResults])./ (state_data.(plot_state_3)(1).population),'-d','Color',color3)

plot([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positive])./ (state_data.(plot_state_4)(1).population),'-^','Color',color4,'MarkerFaceColor',color4)
plot([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).totalTestResults])./ (state_data.(plot_state_4)(1).population),'-^','Color',color4)

% plot(linspace(1,30,100),2.^(linspace(1,30,100)/1))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/2))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/3))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/4))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/5))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/6))
% plot(linspace(1,30,100),2.^(linspace(1,30,100)/7))

set(gca,'yscale','log')
%set(gca,'xscale','log')
axis([0,45,10^-4,100])
legend(plot_state_1, plot_state_2, plot_state_3, plot_state_4, 'positive tests', 'total tests')
xlabel('Days Since First Positive') 
ylabel({'Total Positive';'and Total Tests';'(% of Population)'}) 
axis square
box on
hYLabel = get(gca,'YLabel');
set(hYLabel,'rotation',0,'VerticalAlignment','middle','HorizontalAlignment','right')
hYLabel.Position(1) = hYLabel.Position(1)-0;
saveas(gcf,'plot.png','png')



% % Median Doubling
% 
% plot_state_1 = 'MA';
% plot_state_2 = 'OH';
% plot_state_3 = 'NY';
% plot_state_4 = 'CA';
% 
% figure
% hold on
% 
% plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-1).positiveDays], [state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).medDoubleThree],'-o','Color',color1)
% plot([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays-1).positiveDays], [state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).medDoubleThree],'-o','Color',color2)
% plot([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays-1).positiveDays], [state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).medDoubleThree],'-o','Color',color3)
% plot([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays-1).positiveDays], [state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).medDoubleThree],'-o','Color',color4)
% 
% %set(gca,'yscale','log')
% %set(gca,'xscale','log')
% axis([0,30,0,15])
% legend(plot_state_1, plot_state_2, plot_state_3, plot_state_4)
% xlabel('Days Since First Positive') 
% ylabel('Three Day Median of Daily Doubling Time (days)') 
% axis square
% box on
% saveas(gcf,'double_med.png','png')


% Three day daily doubling

plot_state_1 = 'MA';
plot_state_2 = 'OH';
plot_state_3 = 'NY';
plot_state_4 = 'TN';

figure
hold on

plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-3).positiveDays], [state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-3).currentDoubleRate_three],'-o','Color',color1)
plot([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays-3).positiveDays], [state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays-3).currentDoubleRate_three],'-s','Color',color2)
plot([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays-3).positiveDays], [state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays-3).currentDoubleRate_three],'-+','Color',color3)
plot([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays-3).positiveDays], [state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays-3).currentDoubleRate_three],'-^','Color',color4)


%set(gca,'yscale','log')
%set(gca,'xscale','log')
axis([0,45,0,15])
legend(plot_state_1, plot_state_2, plot_state_3, plot_state_4)
xlabel('Days Since First Positive') 
ylabel('Daily Doubling Time over Three Day Period (days)') 
axis square
box on
saveas(gcf,'double_three.png','png')


% Negative Tests

plot_state_1 = 'MA';
plot_state_2 = 'OH';
plot_state_3 = 'NY';
plot_state_4 = 'CA';

figure
hold on

plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults] - [state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive])./ (state_data.(plot_state_1)(1).population),'-o','Color',color1)
plot([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).totalTestResults] - [state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays).positive])./ (state_data.(plot_state_2)(1).population),'-s','Color',color2)
plot([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).totalTestResults] - [state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays).positive])./ (state_data.(plot_state_3)(1).population),'-+','Color',color3)
plot([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).totalTestResults] - [state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays).positive])./ (state_data.(plot_state_4)(1).population),'-^','Color',color4)

set(gca,'yscale','log')
%set(gca,'xscale','log')
axis([0,30,10.^-6,100])
legend(plot_state_1, plot_state_2, plot_state_3, plot_state_4)
xlabel('Days Since First Positive') 
ylabel('Percent of Population Negative Results') 
axis square
box on
saveas(gcf,'negative.png','png')



% Negative Rate

plot_state_1 = 'MA';
plot_state_2 = 'OH';
plot_state_3 = 'NY';
plot_state_4 = 'TN';
plot_state_5 = 'CA';

figure
hold on

prune = 15;

plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-prune).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-prune).positiveIncrease] ./ [state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-prune).totalTestResultsIncrease]),'-o','Color',color1)
plot([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays-prune).positiveDays], 100.*([state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays-prune).positiveIncrease] ./ [state_data.(plot_state_2)(1:state_data.(plot_state_2)(1).positiveDays-prune).totalTestResultsIncrease]),'-s','Color',color2)
plot([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays-prune).positiveDays], 100.*([state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays-prune).positiveIncrease] ./ [state_data.(plot_state_3)(1:state_data.(plot_state_3)(1).positiveDays-prune).totalTestResultsIncrease]),'-+','Color',color3)
plot([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays-prune).positiveDays], 100.*([state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays-prune).positiveIncrease] ./ [state_data.(plot_state_4)(1:state_data.(plot_state_4)(1).positiveDays-prune).totalTestResultsIncrease]),'-^','Color',color4)
plot([state_data.(plot_state_5)(1:state_data.(plot_state_5)(1).positiveDays-prune).positiveDays], 100.*([state_data.(plot_state_5)(1:state_data.(plot_state_5)(1).positiveDays-prune).positiveIncrease] ./ [state_data.(plot_state_5)(1:state_data.(plot_state_5)(1).positiveDays-prune).totalTestResultsIncrease]),'-*','Color',color5)

%set(gca,'yscale','log')
%set(gca,'xscale','log')
%axis([0,30,10.^-6,100])
legend(plot_state_1, plot_state_2, plot_state_3, plot_state_4, plot_state_5)
xlabel('Days Since First Positive') 
ylabel('Current Day Positive Test (%)') 
axis square
box on
saveas(gcf,'positive_rate.png','png')



if ~exist('State_Plots', 'dir')
       mkdir('State_Plots')
end
cd('State_Plots')


for state_num = 1:52
		
	plot_state_1 = state_abrv{state_num};
		
	figure
	hold on
	
	fill([[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays])],    100.*([[state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive], flip([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults])])./ (state_data.(plot_state_1)(1).population), color1,'FaceAlpha', 0.25,'EdgeColor', color1)
		
	plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positive])./ (state_data.(plot_state_1)(1).population),'-o','Color',color1,'MarkerFaceColor',color1)
	plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays).totalTestResults])./ (state_data.(plot_state_1)(1).population),'-o','Color',color1)
	
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/1))
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/2))
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/3))
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/4))
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/5))
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/6))
	% plot(linspace(1,30,100),2.^(linspace(1,30,100)/7))
	
	set(gca,'yscale','log')
	%set(gca,'xscale','log')
	axis([0,45,10^-4,100])
	legend(state_names{state_num}, 'positive tests', 'total tests')
	xlabel('Days Since First Positive')
	ylabel({'Total Positive';'and Total Tests';'(% of Population)'})
	axis square
	box on
	hYLabel = get(gca,'YLabel');
	set(hYLabel,'rotation',0,'VerticalAlignment','middle','HorizontalAlignment','right')
	hYLabel.Position(1) = hYLabel.Position(1)-0;
	saveas(gcf,[plot_state_1,'.png'],'png')

end

cd ..
	
close all



if ~exist('State_Doubling', 'dir')
       mkdir('State_Doubling')
end
cd('State_Doubling')

for state_num = 1:52
		
	plot_state_1 = state_abrv{state_num};
		
	figure
	hold on
	
	plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-3).positiveDays], [state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-3).currentDoubleRate_three],'-o','Color',color1)

	%set(gca,'yscale','log')
	%set(gca,'xscale','log')
	axis([0,45,0,15])
	xlabel('Days Since First Positive') 
	ylabel({'Daily Doubling Time';'Three Day Period';'(days)'}) 
	legend(state_names{state_num})
	hYLabel = get(gca,'YLabel');
	set(hYLabel,'rotation',0,'VerticalAlignment','middle','HorizontalAlignment','right')
	hYLabel.Position(1) = hYLabel.Position(1)-0;
	axis square
	box on
	saveas(gcf,[plot_state_1,'_double_three.png'],'png')

end

cd ..
	
close all
	
	
if ~exist('Positive_Rate', 'dir')
       mkdir('Positive_Rate')
end
cd('Positive_Rate')

for state_num = 1:52
		
	plot_state_1 = state_abrv{state_num};
	
	figure
	hold on
	
	prune = 15;
	
	plot([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-prune).positiveDays], 100.*([state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-prune).positiveIncrease] ./ [state_data.(plot_state_1)(1:state_data.(plot_state_1)(1).positiveDays-prune).totalTestResultsIncrease]),'-o','Color',color1)
	
	%set(gca,'yscale','log')
	%set(gca,'xscale','log')
	axis([0,45,0,100])
	legend(state_names{state_num})
	xlabel('Days Since First Positive')
	ylabel({'Current Day';'Positive Test';'(%)'})
	
	hYLabel = get(gca,'YLabel');
	set(hYLabel,'rotation',0,'VerticalAlignment','middle','HorizontalAlignment','right')
	hYLabel.Position(1) = hYLabel.Position(1)-0;
	
	axis square
	box on
	saveas(gcf,[plot_state_1,'_positive_rate.png'],'png')
	
end

cd ..

close all

	