//Clears any previous overlay on the image.
Overlay.remove;

/* Default Values*/
sensitivity=100;
step=5;
resolution=1;
samplenumber=2000;

/*Code*/ 
// This code makes a rectangle in the upper left and checkes the mean intensity in order to get a background value
makeRectangle(0,0,10,10);
getStatistics(area,mean);
background=mean;

print("Background Intensity: "+background);

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
	
		currentx=currentx+x2-x1;
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

print("Number of regions measured: "+finalx1.length);

// Analyze the identified vessel segments
for(n=0;n<finalx1.length;n++) {

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
				finalx1[n]=x1;
				finalx2[n]=x2;
				finaly1[n]=y1;
				finaly2[n]=y2;
			}
			rotate_angle=rotate_angle-1;
		} while(rotate_angle>0);
		
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
			if(final_line_x.length>0 && final_line_y.length>0) {
			makeLine(final_line_x[0],final_line_y[0],final_line_x[k-1],final_line_y[k-1]);
			setResult("Diameter (pixels)",n,final_line_x.length);
		}
			else {
			setResult("Diameter (pixels)",n,0);
			}
		Overlay.addSelection;
		updateResults();
	}

