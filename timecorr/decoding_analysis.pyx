import numpy as np
cimport numpy as np
from random import shuffle
import h5py
import hypertools as hyp
from timecorr import timecorr
from math import exp, sqrt, pi

def decoding_analysis():
    cdef int time_len, activations_len, subj_num, timepoint, subject, tests, gaussian_variance, estimation_range
    cdef double accuracy
    cdef np.ndarray[double,ndim=2] covariance1, covariance2, correlation, correlation1, correlation2
    cdef np.ndarray[double,ndim=4] coefficients
    cdef np.ndarray gaussian_array, corr1, corr2

    repetitions = 20
    accuracy_list = np.zeros([1,repetitions])
    gaussian_variance = 100
    estimation_range = 3


    #load in data
    # filename = "../data/weights.mat"
    activations = hyp.tools.load('weights')

    # #generate activations from subject weights
    activations = np.array(activations)
    subj_num, time_len, activations_len = activations.shape
    coefficients = np.zeros([time_len,time_len,activations_len,activations_len])
    subj_indices = np.arange(subj_num)
    gaussian_array = np.array([exp(-timepoint**2/2/gaussian_variance)/sqrt(2*pi*gaussian_variance) for timepoint in range(-time_len+1,time_len)])

    for timepoint in range(time_len):
        coefficient = gaussian_array[(time_len-1-timepoint):(2*time_len-1-timepoint)]
        coefficient = coefficient/np.sum(coefficient)
        coefficients[timepoint] = np.swapaxes(np.tile(np.tile(coefficient,[activations_len,1]),[activations_len,1,1]),2,0)
    print(coefficients.shape[0],coefficients.shape[1],coefficients.shape[2],coefficients.shape[3])
    h5f = h5py.File('coefficients.h5', 'w')
    h5f.create_dataset('dataset_1', data=coefficients)
    h5f.close()


    for tests in range(repetitions):
        shuffle(subj_indices)
        corr1 = timecorr(activations[subj_indices[:(subj_num/2)],:,:],gaussian_variance,estimation_range,"across","coefficients.h5")
        corr2 = timecorr(activations[subj_indices[(subj_num/2):],:,:],gaussian_variance,estimation_range,"across","coefficients.h5")
        correlation = np.corrcoef(corr1,corr2)
        correlation1 = correlation[:time_len,time_len:]
        correlation2 = correlation[time_len:,:time_len]
        # accuracy = 0.0
        error_list = [abs((np.argmax(correlation1[timepoint])+np.argmax(correlation2[timepoint]) - 2*timepoint)) for timepoint in range(time_len)]
        # for timepoint in range(time_len):
            # if np.argmax(correlation1[timepoint])==timepoint:
            #     accuracy+=1
            # if np.argmax(correlation2[timepoint])==timepoint:
            #     accuracy+=1
        accuracy_list[0,tests]=float(sum(error_list))/(time_len*2)
        # accuracy_list[0,tests]=accuracy/(time_len*2)
        print(tests, correlation.shape[0],correlation.shape[1],accuracy_list[0,tests])

    print accuracy_list
    print(np.mean(accuracy_list))
