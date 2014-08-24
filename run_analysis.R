# Returns one data set by reading and merging all component files.
# Data set comprises of the X values, Y values and Subject IDs.
# This extracts only the measurements on the mean and standard deviation for each measurement.
# The columns in the subset is selected only those columns that have "mean()" or "std()" in their names.
# The pathPrefix indicates the path where the data files can be found.
# The fileNameSuffix indicates the file name suffix to be used to create the complete file name.
readData <- function(fileNameSuffix, pathPrefix) {
  fpath <- file.path(pathPrefix, paste0("y_", fileNameSuffix, ".txt"))
  y_data <- read.table(fpath, header=F, col.names=c("ActivityID"))
  
  fpath <- file.path(pathPrefix, paste0("subject_", fileNameSuffix, ".txt"))
  subjectData <- read.table(fpath, header=F, col.names=c("SubjectID"))
  
  # read the column names
  data_cols <- read.table("features.txt", header=F, as.is=T, col.names=c("MeasureID", "MeasureName"))
  
  # read the X data file
  fpath <- file.path(pathPrefix, paste0("X_", fileNameSuffix, ".txt"))
  data <- read.table(fpath, header=F, col.names=data_cols$MeasureName)
  
  # names of subset columns required
  subjectDataColumns <- grep(".*mean\\(\\)|.*std\\(\\)", data_cols$MeasureName)
  
  # subset the data
  data <- data[,subjectDataColumns]
  
  # append the activity id and subject id columns
  data$ActivityID <- y_data$ActivityID
  data$SubjectID <- subjectData$SubjectID
  
  # return the data
  data
}

# read test data set, in a folder named "test", and data file names suffixed with "test"
readTestData <- function() {
  readData("test", "test")
}

# read test data set, in a folder named "train", and data file names suffixed with "train"
readTrainData <- function() {
  readData("train", "train")
}

# Merge both train and test data sets
mergeData <- function() {
  data <- rbind(readTestData(), readTrainData())
  cnames <- colnames(data)
  cnames <- gsub("\\.+mean\\.+", cnames, replacement="Mean")
  cnames <- gsub("\\.+std\\.+",  cnames, replacement="Std")
  colnames(data) <- cnames
  data
}

# Add the activity names as another column
applyActivityLabel <- function(data) {
  activity_labels <- read.table("activity_labels.txt", header=F, as.is=T, col.names=c("ActivityID", "ActivityName"))
  activity_labels$ActivityName <- as.factor(activity_labels$ActivityName)
  data_labeled <- merge(data, activity_labels)
  data_labeled
}

# Combine training and test data sets and add the activity label as another column
mergedLabelData <- applyActivityLabel(mergeData())

#Creating a data set tha tis tidy with the average of variables and each subject
library(reshape2)

# melting
idVariables = c("ActivityID", "ActivityName", "SubjectID")
measure_vars = setdiff(colnames(mergedLabelData), idVariables)
melted_data <- melt(mergedLabelData, id=idVariables, measure.vars=measure_vars)

# casting 
dcast(melted_data, ActivityName + SubjectID ~ variable, mean)    

# The tidy data set
tidyData <- getTidyData(mergedLabelData)
write.table(tidyData, "tidy.txt")