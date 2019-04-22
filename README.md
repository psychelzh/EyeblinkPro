# Eye blink project

This is used to store codes used in the eye blink rate calculation of EOG recordings in one experiment.

## Usage

There are three main steps to calculate and determine eye blink based on [this paper](http://biomedical-engineering-online.biomedcentral.com/articles/10.1186/1475-925X-12-110).

1. Calling `Extract_EOG` to get all the "EOG" data from the EEG recordings.
1. Calling `Calc_Blink` to analyze the "EOG" data and detect all the eye blinks.
1. Calling `Check_Blink` to check visually (manually) the eye blink detection validity.
