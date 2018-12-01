function [sites] = stageDataReading(functionInput,sites,state,instance)
% This stage reads the data from the site and computes summary stats.
[dataMatrix_noImputation,dataHeader] = getData(functionInput,instance);
%% 
% add your SPARQL query and data-preprocessing in the function getData().
% the output needs to be
% dataMatrix_noImputation: a matrix with numeric values and NaNs 
% dataHeader: a cell with column headers for the matrix
%%

% quality check: reorder data and data header to obey order in instance.variableNames
% [dataMatrix_noImputation,dataHeader] = reorderData(dataMatrix_noImputation,dataHeader,instance);

% save un-imputed data for later iterations
save(fullfile(functionInput.pathToTempFolder,'data_noImputation.mat'),'dataMatrix_noImputation','dataHeader');

% compute summary stats for variables at this site, needed for
% normalization
[sites] =  computeSummaryStats(dataMatrix_noImputation,sites);
display('Cox regression calculation')
%--------------------------Distributed Learning Radiomics ----------
% dataMatrix=['Fstat.energy','Fmorph.comp.2','Frlm.rlnu','Fszm.glnu','vitalStatusLabel','survivalValue']
data_test = dataMatrix_noImputation;
% predictive features
X_test = data_test(:,1:4);
% target: Survival.time
y_test = data_test(:,6);
% observed event: deadstatus.event
event_test = data_test(:,5);

%% data pre-processing
% fill NaNs
%y_test(isnan(y_test)) = 710 + 365 * randn(size(find(isnan(y_test))));
% drop NaNs
y_test = y_test(~isnan(y_test));
X_test = X_test(~isnan(y_test), :);
event_test = event_test(~isnan(y_test));

% data transformation using log10
% X_train = log10(X_train);
X_test = log10(X_test);

%### scale predictive features
scale_pred = true;
% scaler type: StandardScaler() or MinMaxScaler()
scale_type = 'StandardScaler'; %'MinMaxScaler';

% min-max scaling
% data from Lung-1
mean_train = [8.5763   -0.6336    2.8519    3.2169];
std_train = [0.5735    0.2044    0.8169    0.7196];
if scale_pred && strcmp(scale_type, 'MinMaxScaler')

%     X_train = (X_train - ones(size(X_train(:, 1))) * min(X_train)) ./...
%         (ones(size(X_train(:, 1))) * (max(X_train) - min(X_train)));
    X_test = (X_test - ones(size(X_test(:, 1))) * min(X_test)) ./...
        (ones(size(X_test(:, 1))) * (max(X_test) - min(X_test)));
    
% mean-centering and standardization
elseif scale_pred && strcmp(scale_type, 'StandardScaler')
    
%     X_train = (X_train - ones(size(X_train(:, 1))) * mean(X_train)) ./...
%         (ones(size(X_train(:, 1))) * std(X_train));

    X_test = (X_test - ones(size(X_test(:, 1))) * mean_train) ./...
        (ones(size(X_test(:, 1))) * std_train);
end

% coefficients of cox regression on Lung1
b = [0.0517;-0.0151;0.0764;0.0788];
% separation median
sep_median_train = 0.0297;

% Validation results on Lung-2
SurvTime_lowrisk = y_test((X_test * b) > sep_median_train);
DeathStatus_lowrisk = event_test((X_test * b) > sep_median_train);
SurvTime_highrisk = y_test((X_test * b) <= sep_median_train);
DeathStatus_highrisk = event_test((X_test * b) <= sep_median_train);

% low and high groups of Lung2
test_low = [SurvTime_lowrisk;DeathStatus_lowrisk];
test_high = [SurvTime_highrisk;DeathStatus_highrisk];
% save KM results in sites
kaplanmeier.SurvTime_lowrisk = SurvTime_lowrisk;
kaplanmeier.DeathStatus_lowrisk = DeathStatus_lowrisk;
kaplanmeier.SurvTime_highrisk = SurvTime_highrisk;
kaplanmeier.DeathStatus_highrisk = DeathStatus_highrisk;
sites.kaplanmeier = kaplanmeier;

%% Kaplan-Meier survival curves
% validation
[f1_test,x1_test] = ecdf(y_test((X_test * b) > sep_median_train), 'function', 'survivor',...
    'censoring', ~event_test((X_test * b) > sep_median_train), 'bounds', 'on');
hold on;
[f2_test,x2_test] = ecdf(y_test((X_test * b) <= sep_median_train), 'function', 'survivor',...
    'censoring', ~event_test((X_test * b) <= sep_median_train), 'bounds', 'on');

% result timelines and estimated probabilities
bigger_median = [f1_test,x1_test]
smaller_median = [f2_test,x2_test]

end

% Example SPARQL query:
% SELECT ?patient ?disease
% WHERE {
%     ?patient rdf:type ncit:C16960.
%     ?patient roo:has_disease ?disease.
% }