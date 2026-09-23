function [S1, S2, M1A, M1B] = MAIN_SC_BINNED(animal, session, all)

% animal = 'sm041'
% session = '1'
% all = control_choice(1);

% [release] path handled by startup_sm.m: addpath(genpath('Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\svm'));
% [release] path handled by startup_sm.m: addpath('Z:\Dropbox\Dropbox\Chen Lab Team Folder\Analysis Suite\Secondary Analysis\GENERAL_SVM');

load([[smroot() 'Analysis/preprocessing/'] animal '-' session '_preprocess_pca.mat']);
load([[smroot() 'Animals/'] animal '\' animal '-' session '.mat']);


S1 = run_comparison(CaA0, tr_include,all);
S2 = run_comparison(CaA1, tr_include,all);
M1A = run_comparison(CaA2, tr_include,all);
M1B = run_comparison(CaA3, tr_include,all);