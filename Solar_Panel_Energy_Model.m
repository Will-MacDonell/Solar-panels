clear all; close all;
%% Section I - Defining Variables
%This section defines variables. Such as geographic location, nearby
%weather station data, solar panel efficiencies, energy demands, and
%buy/sell prices.

Solar_data_file = "Westmidlands_solar_data.mat"

Solar_var_name = string(whos('-file',Solar_data_file).name);
Chosen_solar_data = load(Solar_data_file).midasopenukradiationobsdv201901westmidlands00586winterbourneuni;
ER = load('ED_data_weekly.mat').mean_week;

time=Chosen_solar_data{:,21};
rad=Chosen_solar_data{:,9}/3.600;%from kj/m2 to w/m2

calculation_factor = 1.8; %this is currently a fudge factor
solar_panel_efficiency = 0.2;%photo voltaic efficiency of panel
latitude=52.439017; %Solar panel geographical coordinates
longitude=-1.937303;%Solar panel geographical coordinates
rotation=180; %Solar panel angle (0=North)
solar_panel_surface_area = 40; %m2
batery_size=10;%kwh - a battery allows you to store solar energy and buy electricity from the grid at a low cost to use in times when cost increases. So you can buy energy overnight for cheap and use in the day.
electrical_sell_price = 0.055; %£ - price grid will buy surplus electricity
electrical_buy_price_night = 0.05; %£ - price grid will sell energy at night time
electrical_buy_price_day = 0.1389; %£ - price grid will sell energy in day time
gas_buy_price = 0.0326; %£ - price grid will sell nat gas
grid_connection_fee = 0.25; %£/day 
gas_grid_connection_fee = 0.1; %£/day

%% Section II - Assessing the Actual Solar Radiation Data for the Specified Location
%This section plots the daily and hourly solar radiation data from the
%inputted data set.

figure('color','w','units','normalized','Position',[0 0 1 0.5])
subplot(2,2,1:2)
plot(time,rad,'m')
xlabel('Time')
ylabel('Solar Irradiation, w m^{-2}')
ylim([-inf 950])
grid on

title({'Actual Hourly Solar Irradiation Data Collected at Birmingham Weather Station'})

set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',16)

subplot(2,2,3)
plot(time,rad,'r','LineWidth',2)
tstart = datetime(2011,7,23,0,0,0);
tend = datetime(2011,7,26,0,0,0);
xlim([tstart,tend]);
xlabel('Time')
ylabel('Solar Irradiation, w m^{-2}')
ylim([-inf inf])
grid on

title('Example Summers Days')

set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',16)

subplot(2,2,4)
plot(time,rad,'b','LineWidth',2)
tstart = datetime(2011,11,24,0,0,0);
tend = datetime(2011,11,27,0,0,0);
xlim([tstart,tend]);
xlabel('Time')
ylabel('Solar Irradiation, w m^{-2}')
ylim([-inf 220])
grid on

title('Example Winters Days')

set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',16)

%% Section III - Calculating the relative position of the sun at a specified location as a function of Time
%This section calculates the angular position of the sun above the
%geographical coordinates of the solar panel location for every hour of
%every day of year X. This is then used to find the angles between the
%plane of the solar panel and the sun's rays.

for i=1:length(time)
  
dt=datenum(time(i));
time_zone=1;
dst=1;

[angles,projection] = solarPosition(dt,latitude,longitude, time_zone,rotation,dst);
ang(i,:)=angles;
proj(i,:)=projection;
end

figure('color','w','units','normalized','Position',[0 0 1 0.5])

grid on

title({'Sun Position'})

x = (time)';
zen = ang(:,1)-35;
aze = ang(:,2);
plot(time,zen,time,aze)
legend('ZENITH','AZIMUTH')
xlabel('Time')
ylabel('Angle')
set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',16)

energy=abs(rad.*(cos(aze).*cos(zen)));
q=find(isnan(energy));
energy(q)=0;

%The absolute energy of the solar radiation that lands on the solar panel
%plane is now calculated. Below takes this valve and finds the output power
%of the solar plans based on the position of the sun and real solar radition
%data for every hour of the yeat.


ef = calculation_factor * solar_panel_efficiency;

output=ef*energy;

noofdays=[1:1:365];

%This calculates the daily electricity produced over the year
for i=1:365
    clear p
    p=find(day(time,'dayofyear')==noofdays(i));
    
    DailyTime(i)={time(p)};
    
    DailyEnergyin(i)={energy(p)};
    
    DailyEnergyout(i)={output(p)};
    
    if i==354
        timenum=1;
    else
    timenum=datenum(DailyTime{i});
    timenum=(timenum-timenum(1))*24;
    
    DailyOUTPUT(i)=trapz(timenum,DailyEnergyout{i})*solar_panel_surface_area/1000;
    end
end

%The data is then plotted in the following code

totaloutput=sum(DailyOUTPUT);

figure('color','w','units','normalized','Position',[0 0 1 0.9])
plot(DailyOUTPUT)
xlabel('Day')
ylabel({'Daily Electricity',' Produced, kWh'},'color','r')
title('Energy Produced on Evergy Day of the year, kWh')

figure('color','w','units','normalized','Position',[0 0 0.88 0.8])
subplot(3,100,1:45)
yyaxis left
plot(time,rad,'b','LineWidth',1.2)
ylim([0 2500])
ylabel('Solar Irradiation, w m^{-2}','Color','b')
set(gca,'YColor','b')
hold on
yyaxis right
bar(datetime(2011,1,[1:365],12,0,0),DailyOUTPUT,'r','LineWidth',2,'FaceAlpha',0.3)
xlabel('Time')
ylabel({'Daily Electricity',' Produced, kWh m^{-2}'},'color','r')
title('Daily Solar Energy Analysis')
set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',15,'YColor','r')

subplot(3,100,60:100)
yyaxis left
plot(time,rad,'b','LineWidth',1.2)
ylim([0 2500])
ylabel('Solar Irradiation, w m^{-2}','Color','b')
set(gca,'YColor','b')
hold on
yyaxis right
bar(datetime(2011,1,[1:365],12,0,0),DailyOUTPUT,'r','LineWidth',1,'FaceAlpha',0.3)
xlabel('Time')
ylabel({'Daily Electricity',' Produced, kWh m^{-2}'},'color','r')
xlim([datetime(2011,6,24,0,0,0),datetime(2011,7,6,0,0,0)])
title('Zoomed in Daily Solar Energy Analysis')

set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',15,'YColor','r')

%This calculates the weekly electricity produced throughout the year
for i=1:52
    clear p
    p=find(week(time,'weekofyear')==i);
    
    WeeklyTime(i)={time(p)};
    
    WeeklyEnergyin(i)={energy(p)};
    
    WeeklyEnergyout(i)={output(p)};
    
    if i==354
        timenum=1;
    else
    timenum=datenum(WeeklyTime{i});
    timenum=(timenum-timenum(1))*24;
    
    WeeklyOUTPUT(i)=trapz(timenum,WeeklyEnergyout{i})*solar_panel_surface_area/1000;
    end
end

subplot(3,10,11:20)
yyaxis left
plot(time,rad,'b','LineWidth',1.2)
ylim([0 2500])
ylabel('Solar Irradiation, w m^{-2}','Color','b')
set(gca,'YColor','b')
hold on
yyaxis right
bar([(time(1)+days(3)):days(7):(time(1)+days(361))],WeeklyOUTPUT,'r','LineWidth',1,'FaceAlpha',0.3)
xlabel('Time')
ylabel({'Weekly Electricity',' Produced, kWh m^{-2}'},'color','r')

title('Weekly Solar Energy Analysis')

set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',15,'YColor','r')


%This calculates the monthly energy produced over the year
for i=1:12
    clear p
    p=find(month(time,'monthofyear')==i);
    
    MonthlyTime(i)={time(p)};
    
    MonthlyEnergyin(i)={energy(p)};
    
    MonthlyEnergyout(i)={output(p)};
    
    if i==354
        timenum=1;
    else
    timenum=datenum(MonthlyTime{i});
    timenum=(timenum-timenum(1))*24;
    
    MonthlyOUTPUT(i)=trapz(timenum,MonthlyEnergyout{i})*solar_panel_surface_area/1000;
    end
end

subplot(3,10,21:30)
yyaxis left
plot(time,rad,'b','LineWidth',1.2)
ylim([0 2500])
ylabel('Solar Irradiation, w m^{-2}','Color','b')
set(gca,'YColor','b')
hold on
yyaxis right
bar(time(1)+calmonths(1:12)-days(15),MonthlyOUTPUT,'r','LineWidth',1,'FaceAlpha',0.3)
xlabel('Time')
ylabel({'Monthly Electricity',' Produced, kWh m^{-2}'},'color','r')

title('Monthly Solar Energy Analysis')

set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',15,'YColor','r')


%% Section IV - Calculating energy demand through the year and analysing energy flows.
% This section defines the energy demand over a Jan-December. This data is
% then used to calculate the energy flow to and from the national grid over
% a year (i.e. in the summer, there is likely a surplus of energy generated
% and in winter a shortfall). The topic of energy costs and prices is
% introduced, and the balance sheet is calculated over the year. Energy
% storage batteries are also introduced to show that hour cost efficiencies
% can easily be increased.
% 

ER = load('ED_data_weekly.mat').mean_week;


figure('color','w','units','normalized','Position',[0 0 0.5 0.8])
subplot(3,1,1)
plot([(time(1)+days(3)):days(7):(time(1)+days(361))],ER,'b','LineWidth',2)
hold on
bar([(time(1)+days(3)):days(7):(time(1)+days(361))],WeeklyOUTPUT/(7),'r','LineWidth',1,'FaceAlpha',0.3)
xlabel('Time')
ylabel({'Renewable Electricity','kWh day^{-1}'})
set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',14,'YColor','r')
title('Total Electricity Demand and Production over the Year')
legend('Average Daily Demand','Average Daily Production')

subplot(3,1,2)
EnergyFlow=WeeklyOUTPUT/(7)-ER;
bar([(time(1)+days(3)):days(7):(time(1)+days(361))],EnergyFlow,'m','LineWidth',1,'FaceAlpha',0.3)
xlabel('Time')
ylabel({'Energy Flow','kWh day^{-1}'})
set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',14,'YColor','r')
title('Electrical Energy Flow from House to Grid over the Year')
legend('Average Daily Flow')

l=length(EnergyFlow);
cost=zeros(l,1);
costNB=zeros(l,1);



for i=1:l
    if EnergyFlow(i)>0
        cost(i)=EnergyFlow(i)*electrical_sell_price*7-7*grid_connection_fee;
    else
       if abs(EnergyFlow(i))>batery_size
           cost(i)=-batery_size*electrical_buy_price_night*7-7*grid_connection_fee-(abs(EnergyFlow(i))-batery_size)*electrical_buy_price_day*7;
       else
           cost(i)=EnergyFlow(i)*electrical_buy_price_night*7-7*grid_connection_fee;
       end
   end
end


    
for i=1:l
    if EnergyFlow(i)>0
        costNB(i)=EnergyFlow(i)*electrical_sell_price*7-7*grid_connection_fee;
    else
           costNB(i)=(EnergyFlow(i)*electrical_buy_price_day*7)-7*grid_connection_fee;
       end
end

subplot(3,1,3)

bar([(time(1)+days(3)):days(7):(time(1)+days(361))],cost,'g','LineWidth',1,'FaceAlpha',0.3)
hold on
plot([(time(1)+days(3)):days(7):(time(1)+days(361))],costNB,'b*')
xlabel('Time')
ylabel({'Money Flow','£ week^{-1}'})
set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',14,'YColor','r')
title('Weekly Profit from Flow of Electrity to Grid')
legend('Money Flow w/ Battery','Money Flow w/o Battery')

%print(gcf,'yearlyflow.png','-dpng','-r1600');legend('Weekly Profit')


%% Section V - Detailed Cost Analysis over the year
%This section looks at the money flow over the course of a year. It
%introduces government bursary schemes as the primary ROI source for solar
%panels.


NormElectricity=zeros(1,52)+6.1;
NormGas=(ER-NormElectricity)*4;

NormElecP=(NormElectricity*7*electrical_buy_price_day+grid_connection_fee*7);
NormGasP=(NormGas*7*gas_buy_price+gas_grid_connection_fee *7);

NormTot=-NormElecP-NormGasP;

 Norm30y=NormTot+[zeros(1,length(NormTot)-1),-2000];
  for i=2:30
      if i==15
       Norm30y=[Norm30y,NormTot+[zeros(1,length(NormTot)-1),-2000]];
      else
      Norm30y=[Norm30y,NormTot];
      end
  end
  

NormTot=-(cumsum(NormElecP)+cumsum(NormGasP));

%calculating gov busary
addition=zeros(52,1);
addition(13)=(50*180+10.5*(365-180))*0.2089/4;
addition(26)=(50*180+10.5*(365-180))*0.2089/4;
addition(39)=(50*180+10.5*(365-180))*0.2089/4;
addition(52)=(50*180+10.5*(365-180))*0.2089/4;

g=cumsum(cost);
gNB=cumsum(costNB);

costjustGSHP=-ER*7*electrical_buy_price_day-7*grid_connection_fee;

totalProf=cumsum(cost+addition);
totalProfNB=cumsum(costNB+addition);

total30y=[totalProf;totalProf+1*totalProf(end);totalProf+2*totalProf(end);totalProf+3*totalProf(end);totalProf+4*totalProf(end);totalProf+5*totalProf(end);totalProf+6*totalProf(end);7*totalProf(end)+cumsum(cost);7*totalProf(end)+cumsum(cost)+g(end);7*totalProf(end)+cumsum(cost)+g(end)*2;7*totalProf(end)+cumsum(cost)+g(end)*3;7*totalProf(end)+cumsum(cost)+g(end)*4;7*totalProf(end)+cumsum(cost)+g(end)*5;7*totalProf(end)+cumsum(cost)+g(end)*6;7*totalProf(end)+cumsum(cost)+g(end)*7;7*totalProf(end)+cumsum(cost)+g(end)*8;7*totalProf(end)+cumsum(cost)+g(end)*9;7*totalProf(end)+cumsum(cost)+g(end)*10;7*totalProf(end)+cumsum(cost)+g(end)*11;7*totalProf(end)+cumsum(cost)+g(end)*12;7*totalProf(end)+cumsum(cost)+g(end)*13;7*totalProf(end)+cumsum(cost)+g(end)*14;7*totalProf(end)+cumsum(cost)+g(end)*15;7*totalProf(end)+cumsum(cost)+g(end)*16;7*totalProf(end)+cumsum(cost)+g(end)*17;7*totalProf(end)+cumsum(cost)+g(end)*18;7*totalProf(end)+cumsum(cost)+g(end)*19;7*totalProf(end)+cumsum(cost)+g(end)*20;7*totalProf(end)+cumsum(cost)+g(end)*21;7*totalProf(end)+cumsum(cost)+g(end)*22];

total30yNB=[totalProfNB;totalProfNB+1*totalProfNB(end);totalProfNB+2*totalProfNB(end);totalProfNB+3*totalProfNB(end);totalProfNB+4*totalProfNB(end);totalProfNB+5*totalProfNB(end);totalProfNB+6*totalProfNB(end);7*totalProfNB(end)+cumsum(costNB);7*totalProfNB(end)+cumsum(costNB)+gNB(end);7*totalProfNB(end)+cumsum(costNB)+gNB(end)*2;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*3;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*4;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*5;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*6;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*7;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*8;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*9;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*10;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*11;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*12;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*13;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*14;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*15;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*16;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*17;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*18;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*19;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*20;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*21;7*totalProfNB(end)+cumsum(costNB)+gNB(end)*22];

YearlyMoneyDif=totalProf(end)-NormTot(end);
D=['        Total Money Difference if Renewable Adopted £',num2str(round(YearlyMoneyDif,0))];

figure('color','w','units','normalized','Position',[0 0 0.25 0.3])
plot([(time(1)+days(3)):days(7):(time(1)+days(361))],cumsum(cost),'b-.',[(time(1)+days(3)):days(7):(time(1)+days(361))],totalProf,'r',[(time(1)+days(3)):days(7):(time(1)+days(361))],NormTot,'c--',[(time(1)+days(3)):days(7):(time(1)+days(361))],totalProfNB,'m','LineWidth',2)
xlabel('Time')
ylabel({'Cumulative Profit','Throughout Year, £'})
%text(time(end-1)-days(20),NormTot(end),D,'Rotation',90,'FontSize',13,'Color','r');
set(gca,'Gridalpha',0.2,'LineWidth',1,'FontSize',14,'YColor','r')
title('Money Throughout Year')
legend('Renewable w/o RHI','Renewable w/ RHI','Current','Renewable w/ RHI w/o Battery','Location','best')

%print(gcf,'prof.png','-dpng','-r1600');


%% Section VI - Detailed Long Term ROI Costing
%This section looks at a 30-year cost/income projection of the solar
%panels.




%% Section VII - CO2 Long Term Analysis
%This section assesses the improvements in CO2 costing. 







