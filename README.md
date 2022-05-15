# eeg_pipeline toolbox

This toolbox was designed as part of an independent study to facilitate batch processing of EEG datasets.


## Required toolbox:
* Fieldtrip:  https://www.fieldtriptoolbox.org/
  * Most functionality uses this toolbox and it is required.
  * Robert Oostenveld, Pascal Fries, Eric Maris, and Jan-Mathijs Schoffelen. FieldTrip: Open Source Software for Advanced Analysis of MEG, EEG, and Invasive Electrophysiological Data. Computational Intelligence and Neuroscience, 2011; 2011:156869. https://doi.org/10.1155/2011/156869

* mTRF: https://github.com/mickcrosse/mTRF-Toolbox
  * mTRF analysis uses this toolbox
  * Crosse, M. J., Di Liberto, G. M., Bednar, A., & Lalor, E. C. (2016). The multivariate temporal response function (mTRF) toolbox: a MATLAB toolbox for relating neural signals to continuous stimuli. Frontiers in human neuroscience, 10, 604. https://doi.org/10.3389/fnhum.2016.00604
  

## Getting started
* Use git or just download a zip of this toolbox and extract it somewhere on your hard drive.
* Add eeg_pipeline folder to Matlab's path
* In the command line, run: `saeeg.BatchGUI`
* A gui should appear.
* Use the Data Source button to locate the parent directory of your data
* Select a folder or files individually in the file tree at the left.
* The dropdown box at the right-top of the gui should populate with analysis functions (really their own classes) that are compatible with the data type of selected files.
* Use the settings menu at the top of the gui to customize program behavior.
![main_gui](https://user-images.githubusercontent.com/11509429/168487431-20aac2a7-7963-499b-b0c3-6de23ed82325.PNG)


![data_example](https://user-images.githubusercontent.com/11509429/168487430-4bd2aa23-5d22-4bb0-b41b-bf9e2a3f74de.PNG)

## Adding analysis functions
* To add more functions, copy and modify an existing class under `eeg_pipeline\+saeeg\+agui`
* Each class requires a constructor that takes in `MasterObj` and `parent`.
  * `MasterObj` contains general program information and may or may not be useful
  * `parent` is a handle to the gui panel that can be used for user-modifiable parameters
* Each class also requires two additional functions: `run_analysis` and `create_gui`

### `run_analysis`
* This function accepts the class object and a `saeeg.FileQueue` object (often simply coded as `Q` in existing classes)
* Analysis parameters are specified using the `create_gui` function (see below).
* The `FileQueue`object handles the list of files that are selected and need to be processed.
* Use `Q.CurrentFile` to get the current full path and filename.
* Use `Q.mark_completed` to indicate that the current file has been processed.
* Use `Q.start_next` to kick off the next file in the queue if available.

### `create_gui`
* This function is used to setup a simple interface for specifying parameters.
* Use standard Matlab user interface objects, such as `uieditfield`, `uitable`, etc.
* Read the values of these fields in the `run_analysis` function to specify your analysis parameters.
