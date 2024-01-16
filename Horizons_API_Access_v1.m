%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Horizons API Access
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clearing
clear all
close all

% Planet Names and Corresponding ID's
url = "https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND='MB'";
ID_data = webread(url);
planet_lines = strsplit(ID_data,'\n');
planet_ID = cell(8,3); 

for i = 8:15
    ID_data_lines = strsplit(planet_lines{i},'  ');
    planet_ID{i-7,1} = str2double(ID_data_lines{2}); % Planet ID
    planet_ID{i-7,2} = string(ID_data_lines{3}); % Planet Name
    disp(planet_ID)
end

% Earth Observation Sites
url = 'https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%271%27&OBJ_DATA=%27NO%27&CENTER=%27*@399%27';
site_data = webread(url);
site_lines = strsplit(site_data,'\n');
site_ID = cell(length(site_lines)-106,2); 

for i = 1:length(site_ID)
    site_data_lines = strsplit(site_lines{i+104},'  ');
    disp(site_data_lines)
    disp(i)
    site_ID{i,1} = string(site_data_lines{2}); % Planet ID
    site_ID{i,2} = string(site_data_lines{end}); % Planet Name
end
 
% API Call URL Generation
location = string(input('What city are you in?: ','s'));
ID_index = {};
for i = 1:length(site_ID)
    if contains(lower(site_ID{i,2}),lower(location))
        ID_index{end+1,1} = strtrim(site_ID{i,1});
        ID_index{end,2} = strtrim(site_ID{i,2});
        disp(ID_index)
    end
end

if size(ID_index,1) == 1
    location_ID = ID_index{1,1};
elseif size(ID_index,1) ~= 1
    disp(string(size(ID_index,1)) + " ID's found, please select one:")
    for j = 1:(size(ID_index,1))
        disp("Option " + string(j) + " ID: ("+ID_index{j,1}+") for location: "+string(ID_index{j,2}))
    end
    choice = input("Choose an Option: ");
    location_ID = ID_index{choice,1};
end

start_time = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
end_time = start_time + 0.25;
for i = 1:length(planet_ID)
    url = "https://ssd.jpl.nasa.gov/api/horizons.api?format=text&";
    url = url + "COMMAND='" + num2str(planet_ID{i,1})+"'";
    url = url + "&OBJ_DATA='NO'";
    url = url + "&Make_EPHEM='YES'";
    url = url + "&EPHEM_TYPE='OBSERVER'";
    url = url + "&CENTER=" + "'" + location_ID + '@399' + "'" ;
    url = url + "&START_TIME=" + "'" + string(start_time) + "'";
    url = url + "&STOP_TIME=" + "'" + string(end_time) + "'";
    url = url + "&STEP_SIZE=" + '1m';
    url = url + "&QUANTITIES='4,5'";
    planet_ID{i,3} = url;
end

% File Writing
file_name = 'Azi_Eli.xlsx';
for i = 1:length(planet_ID)
    current_table = table();
    azi_eli_data = webread(planet_ID{i,3});
    azi_eli_lines = strsplit(azi_eli_data,'\n');
    for j = 39:399
        if length(azi_eli_lines) ~= 4 
            azi_eli_row = strsplit(azi_eli_lines{1,j},' ');
            for k = 2:8
                current_table(j-38,k-1) = azi_eli_row(1,k);
            end
        end
    end
    writetable(current_table,file_name,'sheet',i)
end
