/*
VESSEL DIAMETER v. 1.1
By: Jennifer Fang
This macro detects segmented vessels and measures vessel diameter.

Version History:
1.1 - Added batch processing and progress bar updating.
*/


/*=================================================*/
/* Default Values*/
sensitivity=75;
step=10;
resolution=1;
samplenumber=2000;
threshold_measure=10; // Ignore measurements less than this diameter
threshold_max_measure=100; // Ignore measurements greater than this diameter
/*=================================================*/

/*=================================================*/
/*Update Settings based on user query*/
Dialog.create("Settings");
Dialog.addMessage("VESSEL DIAMETER MEASUREMENT SETTINGS");
Dialog.addNumber("Maximum Number of Measurements to Record: ",samplenumber);
Dialog.addSlider("Vessel Diameter Threshold Minimum (pixels) -- Measurements less than this number will be ignored: ", 0, 15, threshold_measure);
Dialog.addSlider("Vessel Diameter Threshold Maximum (pixels) -- Measurements greater than this number will be ignored: ", 20, 200, threshold_max_measure);
Dialog.addSlider("Measurement Sensitivity -- Increase number to reduce noise: ",25,150,sensitivity);
Dialog.addSlider("Scan Step Size -- Increase number to increase the vertical scan step: ",1,20,step);
Dialog.addSlider("Resolution --  Decrease number to increase scanning resolution: ",1,5,resolution);
Dialog.addMessage("Measurements may take a few minutes. Go get some coffee.");
Dialog.show();

samplenumber=Dialog.getNumber();
threshold_measure=Dialog.getNumber();;
threshold_max_measure=Dialog.getNumber();;;
sensitivity=Dialog.getNumber();;;;
step=Dialog.getNumber();;;;;
resolution=Dialog.getNumber();;;;;;


/*=================================================*/
/*Checks to see if there are images open. If not, asks us to choose a directory.*/
if(nImages==0) {

	/*Choose the directory to run the macro on.*/
	path = getDirectory("Choose a Directory");

	filenames = getFileList(path);

	/* Trim out filenames that were retrieved that are actually sub-folders */
	filenames_copy_counter=0;
	for(i=0;i<filenames.length;i++) {
		if(endsWith(filenames[i],"/")) {
			filenames_copy_counter=filenames_copy_counter+1;
			}
		}
	Array.reverse(filenames);
	trim_array_length=filenames.length-filenames_copy_counter;
	filenames=Array.trim(filenames,trim_array_length);
	Array.reverse(filenames);
}

/*User has dragged and dropped images to open*/
else {
filenames=getList("image.titles");
path=File.directory;

//Clears any previous overlay on the image.
Overlay.remove;
}


for(j=0;j<=filenames.length;j++) {
	open(filenames[j]);
	displaywidth=getWidth()/3;
	displayheight=getHeight()/3;
	setLocation(0,0,displaywidth,displayheight);
	run("Set... ", "zoom=200"); // Speeds this macro up immensely
/*=================================================*/
/*File Information*/
root_filename=File.nameWithoutExtension;


root_filename_jpg=root_filename+"_VesselDiameter_jpg";
save_string=path+root_filename_jpg;
save_results_string=path+root_filename+"_VesselDiameter_Results.csv";
save_log_string=path+root_filename+"_VesselDiameter_MeasurementSettings.txt";
print("VESSEL DIAMETER SETTINGS");
print("Directory: "+path);
print("Image analysed: "+root_filename);
print("     Maximum Number of Measurements: ",samplenumber,"\n     Vessel Diameter Threshold Minimum (pixels): ",threshold_measure,"\n     Vessel Diameter Threshold Maximum (pixels): ",threshold_max_measure,"\n     Measurement Sensitivity",sensitivity,"\n     Vertical Scan Step Size: ",step,"\n     Resolution: ",resolution);

/*=================================================*/
/*Measure Background*/ 
// This code makes a rectangle in the upper left and checkes the mean intensity in order to get a background value
makeRectangle(0,0,10,10);
getStatistics(area,mean);
background=mean;
print("     Background Intensity: "+background);

/*=================================================*/
/*Scan and Mark*/
currentx=0; // set to 0 to start at the top of the image
currenty=0; // set to 0 to start at the top of the image
finalx1=newArray(100000);
finalx2=newArray(100000);
finaly1=newArray(100000);
finaly2=newArray(100000);
i=0;
do {
	do {
	makeRectangle(currentx,currenty,resolution,resolution);
	getStatistics(area,mean);
	if (mean>background+sensitivity) {
		
		/* Identified a positive region */
			
		testx=currentx+1; //Figure out where the end of the positive area is
		testy=currenty;
		do {
			test=getPixel(testx,testy);
			testx=testx+1;
		} while (test>background+sensitivity);
		makeLine(currentx-20,currenty,testx+20,testy);
				getLine(x1,y1,x2,y2,lineWidth);
				finalx1[i]=x1;
				finalx2[i]=x2;
				finaly1[i]=y1;
				finaly2[i]=y2;
				i=i+1;
			currentx=currentx+threshold_max_measure-threshold_measure-step; // Try not to undersample horizontal vessels.
			
	}
		currentx=currentx+1;
	} while (currentx < getWidth());

	currentx=0;
	currenty=currenty+step;
	
} while (currenty < getHeight()); // For doing the entire image

if(i>samplenumber) {
	//Analyze only the number of vessel segments that the user defines
	finalx1=Array.trim(finalx1,samplenumber);
	finalx2=Array.trim(finalx2,samplenumber);
	finaly1=Array.trim(finaly1,samplenumber);
	finaly2=Array.trim(finaly2,samplenumber);
}
else {
	//User requested more measurements than macro detects
	finalx1=Array.trim(finalx1,i);
	finalx2=Array.trim(finalx2,i);
	finaly1=Array.trim(finaly1,i);
	finaly2=Array.trim(finaly2,i);
}



// Analyze the identified vessel segments
p=0;
Overlay.drawLabels(true);
for(n=0;n<finalx1.length;n++) {
		//Update progress bar
		showProgress(-n/finalx1.length);
		
		// Compare the horizontal vessel segment against rotated lines to identify the angle of segment that is the shortest diameter
		makeLine(finalx1[n],finaly1[n],finalx2[n],finaly2[n]);
		getStatistics(area,mean);
		line_mean_original=mean;
		rotate_angle=180;		
		
		// free rotate and compare mean fluorescence
		line_mean_check=line_mean_original;
		do {
			run("Rotate..."," angle="+rotate_angle);	
 			getStatistics(area,mean);
			line_mean_new=mean;
			// If rotated line is better replace coordinates and draw a new lines
			if(line_mean_new<line_mean_check) {
				line_mean_check=line_mean_new;
				getLine(x1,y1,x2,y2,lineWidth);
				if(getPixel(x1,y1)<=background+sensitivity && getPixel(x2,y2) <=background+sensitivity) {
					finalx1[n]=x1;
					finalx2[n]=x2;
					finaly1[n]=y1;
					finaly2[n]=y2;
					}
			}
			rotate_angle=rotate_angle-1;
		} while(rotate_angle>0);
		
		if(getPixel(finalx1[n],finaly1[n])<=background+sensitivity && getPixel(finalx2[n],finaly2[n])<=background+sensitivity) {
		// Line selection cooresponding to angle of shortest diameter
		makeLine(finalx1[n],finaly1[n],finalx2[n],finaly2[n]);

		// Redraw line to correspond to shortest diameter
		final_line=getProfile();
		Roi.getContainedPoints(xpoints,ypoints);
		final_line_x = newArray(xpoints.length);
		final_line_y = newArray(xpoints.length);
		final_line_mean = newArray(xpoints.length);
		m=0;
		count=0;
			do {
				 if(final_line[m]>background+sensitivity) {
					final_line_mean[count]=final_line[m];
					final_line_x[count]=xpoints[m];
					final_line_y[count]=ypoints[m];
					count=count+1;
					
				}
			m=m+1;
			} while (m<xpoints.length);
		final_line_mean=Array.trim(final_line_mean,count);		
		final_line_x=Array.trim(final_line_x,count);	
		final_line_y=Array.trim(final_line_y,count);
		k=final_line_x.length;
			if(final_line_x.length>threshold_measure && final_line_y.length>threshold_measure && final_line_x.length < threshold_max_measure && final_line_y.length < threshold_max_measure ) {
			makeLine(final_line_x[0],final_line_y[0],final_line_x[k-1],final_line_y[k-1]);
			setResult("Diameter (pixels)",p,final_line_x.length);
			p=p+1;
			Overlay.addSelection;
			Overlay.drawString(p,final_line_x[0]-10,final_line_y[0]);
			updateResults();
		}
			

		}

	}

		print("\n Number of Vessel Diameter Measurements Recorded: "+p+"\n====================");
		saveAs("jpeg",save_string);	
		saveAs("Results",save_results_string);
		close("*");

}
//Completed analysis message!
		showMessage("Analysis complete! Hope you enjoyed your coffee!");

