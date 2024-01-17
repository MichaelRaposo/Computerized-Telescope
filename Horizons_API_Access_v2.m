%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Horizons API Access
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clearing
clear all
close all

% Names and ID's
ID_url = "https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND='MB'";
ID_data = webread(ID_url);          % Records data
ID_lines = strsplit(ID_data,'\n');  % Splits data by line
ID_name_url = cell(8,3);            % Preallocation

for i = 8:15 % Skips first 7 lines
    ID_data_lines = strsplit(ID_lines{i},'  ');         % Splits line data into cells
    planet_ID{i-7,1} = str2double(ID_data_lines{2});    % Records planet ID
    planet_ID{i-7,2} = string(ID_data_lines{3});        % Records planet Name
    disp(planet_ID)
end

% Earth Observation Site Data
site_url = 'https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%271%27&OBJ_DATA=%27NO%27&CENTER=%27*@399%27';
site_data = webread(site_url);              % Records data
site_lines = strsplit(site_data,'\n');      % Splits data by line
site_ID = cell(length(site_lines)-106,2);   % Preallocation

for i = 1:length(site_ID)
    site_data_lines = strsplit(site_lines{i+104},'  '); % Splits line data into cells
    site_ID{i,1} = string(site_data_lines{2});          % Records ID in 1st column
    site_ID{i,2} = string(site_data_lines{end});        % Records Name in 2nd column
end
 
% User Input
ID_index = {}; % Cell Creation
site_found = false;
while site_found == false
    location = string(input('What city are you observing from: ','s')); % Prompts user for input
    for i = 1:length(site_ID) % Iterates through sites
        if contains(lower(site_ID{i,2}),lower(location)) % Checks if site is in current line
            ID_index{end+1,1} = strtrim(site_ID{i,1}); % Records site ID
            ID_index{end,2} = strtrim(site_ID{i,2}); % Records Site Name
            site_found = true;
        end
        if i == length(site_ID) & site_found == false
            disp('City not in database, please enter another city.')
        end
    end
end

% Location ID
if size(ID_index,1) == 1 % Checks if there is only 1 ID
    disp("Site Selected: " + string(ID_index{1,2}))
    location_ID = ID_index{1,1};
else 
    disp(string(size(ID_index,1)) + " ID's found, please select one:") % Prompts user to select from options
    ID_selected = false; % Sets selection ID flag to false
    while ID_selected == false
        for j = 1:(size(ID_index,1))
            disp("Option " + string(j) + " ID: ("+ID_index{j,1}+") for location: "+string(ID_index{j,2}))
        end
        choice = input("Choose an Option: ",'s');
        if isnan(str2double(choice)) == true || str2double(choice) > size(ID_index,1)
            disp("Invalid Option")
        else
            disp("Site Selected: " + string(ID_index{str2double(choice),2}))
            location_ID = ID_index{str2double(choice),1};
            ID_selected = true;
        end
    end
end

% Horizons API URL Generation
start_time = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
end_time = start_time + 0.25;
for i = 1:length(planet_ID)
    coords_url = "https://ssd.jpl.nasa.gov/api/horizons.api?format=text&";
    coords_url = coords_url + "COMMAND='" + num2str(planet_ID{i,1})+"'";
    coords_url = coords_url + "&OBJ_DATA='NO'";
    coords_url = coords_url + "&Make_EPHEM='YES'";
    coords_url = coords_url + "&EPHEM_TYPE='OBSERVER'";
    coords_url = coords_url + "&CENTER=" + "'" + location_ID + '@399' + "'" ;
    coords_url = coords_url + "&START_TIME=" + "'" + string(start_time) + "'";
    coords_url = coords_url + "&STOP_TIME=" + "'" + string(end_time) + "'";
    coords_url = coords_url + "&STEP_SIZE=" + '1m';
    coords_url = coords_url + "&QUANTITIES='4,5'";
    planet_ID{i,3} = coords_url;
end

% File Writing
file_name = 'Azimuth_Elevation.xlsx';
for i = 1:length(planet_ID)
    current_table = table();
    azi_eli_data = webread(planet_ID{i,3});
    azi_eli_lines = strsplit(azi_eli_data,'\n');
    for j = 39:399
        if length(azi_eli_lines) ~= 4 
            azi_eli_row = strsplit(azi_eli_lines{1,j},' ');
            for k = 2:length(azi_eli_row)
                current_table(j-38,k-1) = azi_eli_row(1,k);
            end
        end
    end
    writetable(current_table,file_name,'Sheet',string(planet_ID(i,2)))
end