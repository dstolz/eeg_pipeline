function eeg_preamble

m = mfilename('fullpath');
addpath(fileparts(m));

w = which('ft_defaults');

assert(~isempty(w),'NeedFieldTrip','Main folder for the FieldTrip Toolbox must be on Matlab''s path')
ft_defaults