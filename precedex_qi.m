% Data processing algorithm for Precedex QI project
% For the MATLAB Scientific Programming Language
% Copyright 2023 Washington University
% Created by Zach Vesoulis

% Washington University hereby grants to you a non-transferable, non-exclusive, royalty-free, non-commercial, research license to use and copy the computer code that may be downloaded within this site (the "Software").  You agree to include this license and the above copyright notice in all copies of the Software.  The Software may not be distributed, shared, or transferred to any third party.  This license does not grant any rights or licenses to any other patents, copyrights, or other forms of intellectual property owned or controlled by Washington University.  If interested in obtaining a commercial license, please contact Washington University's Office of Technology Management (otm@dom.wustl.edu).
 
% YOU AGREE THAT THE SOFTWARE PROVIDED HEREUNDER IS EXPERIMENTAL AND IS PROVIDED "AS IS", WITHOUT ANY WARRANTY OF ANY KIND, EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE, OR NON-INFRINGEMENT OF ANY THIRD-PARTY PATENT, COPYRIGHT, OR ANY OTHER THIRD-PARTY RIGHT.  IN NO EVENT SHALL THE CREATORS OF THE SOFTWARE OR WASHINGTON UNIVERSITY BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN ANY WAY CONNECTED WITH THE SOFTWARE, THE USE OF THE SOFTWARE, OR THIS AGREEMENT, WHETHER IN BREACH OF CONTRACT, TORT OR OTHERWISE, EVEN IF SUCH PARTY IS ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

% This code was used to create a figure in the manuscript:
% Dexmedetomidine during therapeutic hypothermia: a multicenter quality initiative to reduce opioid exposure
% M Elliot, KD Fairchild, S Zanelli, C McPherson, and ZA Vesoulis

% This algorithm assumes data is prepared according to the method defined
% in the UVA-CAMA Universal File Converter, located at:
% https://github.com/UVA-CAMA/UniversalFileConverter

% Get the list of MAT files in the present working directory
matFiles = dir('*.mat');

% Loop through each MAT file
for i = 1:length(matFiles)
           
    % Load the MAT file
    filename = matFiles(i).name
    load(filename);
    
    % Process the loaded variables
    
    %find the column for HR
    IndexH = strfind(vname,'/VitalSigns/HR');
    IndexHU = strfind(vname,'HR');
    HR_index = find(not(cellfun('isempty',IndexH)));
    if isempty(HR_index)
        HR_index = find(not(cellfun('isempty',IndexHU)));
    end
    
    %put the located signal into a common variable
    hr_signal=vdata(:,HR_index);

    %set starting point
    low=1;
    high=3600;
    
    %main processing loop, run for 120 hours
    for j=1:120
        
        %define boundaries of each hour using seconds from birth
        start=find(sec_birth==low);
        stop=find(sec_birth==high);

        %account for jitter    
        if isempty(start)
            start=find((sec_birth+2)==low);
        end

        if isempty(stop)
            stop=find((sec_birth+2)==low);
        end

        %conditionally process hour blocks based on the presence or absence
        %of missing data at begining or end of block

        %missing whole hour
        if isempty(start)==1 && isempty(stop)==1
            hr_hourly(i,j)=nan;
        end
    
        %missing start but not end
        if isempty(start)==1 && isempty(stop)==0
            %find value closest to start
            [~, new_start_index] = min(abs(sec_birth - low));
            start=new_start_index;
            hr_hourly(i,j)=nanmean(hr_signal(start:stop));
                     
        end
    
        %not missing
        if isempty(start)==0 && isempty(stop)==0
            hr_hourly(i,j)=nanmean(hr_signal(start:stop));
                                              
        end
    
        low=low+3600;
        high=high+3600;
    

    end
end

%calculate hourly averages, SEM for morphine
combined_hr_morphine=nanmean(hr_hourly(140:202,:),1);
combined_hr_sem_morphine=nansem(hr_hourly(140:202,:),1);

%calculate hourly averages, SEM for dex
combined_hr_dex=nanmean(hr_hourly(1:116,:),1);
combined_hr_sem_dex=nansem(hr_hourly(1:116,:),1);

%calculate hourly averages, SEM for fentanyl
combined_hr_fent=nanmean(hr_hourly(117:139,:),1);
combined_hr_sem_fent=nansem(hr_hourly(117:139,:),1);

%plot HR for each of the three drug classes, using subplot to allow for
%further expansion with other VS, if needed

subplot(1,1,1)
errorbar(combined_hr_morphine,combined_hr_sem_morphine,'k')
hold on
errorbar(combined_hr_dex,combined_hr_sem_dex,'r')
errorbar(combined_hr_fent,combined_hr_sem_fent,'b')
hold off
title("Heart rate")
legend("Morphine","Dex","Fentanyl")
xlabel("Hours since birth")
ylabel("beats per minute")
grid on
