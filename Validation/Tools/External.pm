#!/usr/bin/perl
###############################################################################
# Copyright 2006 -- Thomson R&D France Snc
#                   Technology - Corporate Research
###############################################################################
# File          : External.pm
# Author        : jerome.vieron@thomson.net
# Creation date : 25 January 2006
# Version       : 0.0.1
################################################################################

package External;

#-----------------------#
# System Packages       #
#-----------------------#
use strict;
use IO::File;

#-----------------------#
# Local Constants       #
#-----------------------#
my $ENCODER   = "H264AVCEncoderLibTestStatic";
my $PSNR      = "PSNRStatic";
my $EXTRACTOR = "BitStreamExtractorStatic";
my $DECODER   = "H264AVCDecoderLibTestStatic";
my $RESAMPLER = "DownConvertStatic";

#-----------------------#
# Functions             #
#-----------------------#

###############################################################################
# Function         : platformpath ($)
###############################################################################
#check platform and substitute "/" by "\" if needed
sub platformpath($)
{
	my $exe = shift;

	$exe =~ s|/|\\|g if ($^O =~ /^MS/);
	return $exe;
}

######################################################################################
# Function         : run ($;$$)
######################################################################################
sub run ($;$$)
{
  my $exe 	= shift; #cmd line to execute
  my $log 	= shift; #log filename
  my $dodisplay = shift; #display stdout or not 

 #$dodisplay = 1;
 
  $exe = platformpath($exe);
  
  ::PrintLog("\n $exe\n", $log,$dodisplay);
 
  my $hexe = new IO::File "$exe |";
  (defined $hexe) or die "- Failed to run $exe : $!";
 
  ::PrintLog($hexe, $log, $dodisplay);

  $hexe->close;
	
  my $ret = $?;

  return $ret;
}


######################################################################################
# Function         : Encode ($;$)
######################################################################################
sub Encode($;$)
{
	my $simu=shift;
	my $param=shift;
	my $bin = $param->{path_bin};
		
	::PrintLog(" Encode\t\t\t.......... ");
		
	my $FGSlayer	= $simu->{nbfgslayer};
	my $FGSConf="";
	my $MotConf="";
	my $MotConfCGS="";
	my $DSConf="";
	my $cmd ;
	my $ret;
	
	my $l=-1;
	my $lp1=0;
	my $layer;
	foreach $layer (@{$simu->{layers}})
	{
		$l++;
		$lp1++;	
		if($layer->{bitrate}==0)
		{
			#cgs layer
			#motion for this layer wil have to be computed later
			$MotConf	.= " -mfile $l 2 ".$layer->{motionname};
			$MotConfCGS	.= " -mfile $l 1 ".$layer->{motionname};
		}	
		else
		{
			#Layer with FGS content
			
			$cmd = "$bin$ENCODER -pf ".$simu->{configname}." -bf ".$simu->{bitstreamname}." -numl $lp1  $DSConf $MotConf -mfile $l 2 ".$layer->{motionname}." $FGSConf -anafgs $l $FGSlayer ".$layer->{fgsname}." ".$simu->{singleloopflag};
    		 	$ret = run($cmd, $simu->{logname},0);
  			($ret == 0) or die "problem while executing the command:\n$cmd\n";

			if ($layer->{bitrateDS}>0)
			{
				$DSConf .=" -ds $l ".$layer->{bitrateDS};
			}

			$FGSConf .= " -encfgs $l ".$layer->{bitrate}." ".$layer->{fgsname};

			#motion can be read
			$MotConf	 = "$MotConfCGS -mfile $l 1 ".$layer->{motionname};
			$MotConfCGS	 = "$MotConfCGS -mfile $l 1 ".$layer->{motionname};
		}
	}	
	
	$cmd = "$bin$ENCODER -pf ".$simu->{configname}." -bf ".$simu->{bitstreamname}." -numl $lp1 $DSConf $MotConf $FGSConf ".$simu->{singleloopflag};
 	$ret = run($cmd,$simu->{logname},0);
  	($ret == 0) or die "problem while executing the command:\n$cmd\n";
  	
	
  	return 1;
}

######################################################################################
# Function         : Extract ($;$;$)
######################################################################################
sub Extract($$;$)
{
	my $simu=shift;
	my $test=shift;
	my $param=shift;
	my $bin =$param->{path_bin};
	my $display=1; 

	my $cmd = "$bin$EXTRACTOR ".$simu->{bitstreamname}." ".$test->{extractedname}." -e ".$test->{extractoption}; 
	
	my $ret = run($cmd, $simu->{logname},0);
  	($ret == 0) or die "problem while executing the command:\n$cmd\n";
}

###############################################################################
# Function         : Decode ($;$;$)
###############################################################################
sub Decode($$;$)
{
	my $simu=shift;
	my $test=shift;
	my $param=shift;
	
	my $bin =$param->{path_bin};
	my $tmp =$param->{path_tmp};
	my $display=1; 

	my $cmd ="$bin$DECODER ".$test->{extractedname}." ".$test->{decodedname};
	my $ret = run($cmd, $simu->{logname},0);
  	($ret == 0) or die "problem while executing the command:\n$cmd\n $!";
    	
  	return ComputePSNR($bin,$simu->{logname},$test->{width},$test->{height},$test->{origname},$test->{decodedname},$test->{extractedname},$test->{framerate},"${tmp}psnr.dat");	
 }


###############################################################################
# Function         : ComputePSNR ($$$$$)
###############################################################################
sub ComputePSNR($$$$$$$$$)
{
   my $bin=shift;
   my $log=shift;
   my $width= shift;
   my $height=shift;
   my $refname=shift;
   my $decname=shift;
   my $extname=shift;
   my $framerate = shift;
   my $errname=shift;
   
   my $cmd = "${bin}$PSNR $width $height $refname $decname 0 0 0 $extname $framerate 2> $errname";
   
   my $ret = run($cmd, $log,0);
  ($ret == 0) or die "problem while executing the command:\n$cmd \n $!";

   (-f $errname) or die "Problem the file $errname has not been created $!";
    my $PSNR = new IO::File $errname, "r";
    my $result=<$PSNR>;
    #chomp $result;
    $result =~ s/[\n\r]//g;
    $result =~ s/,/./g;
    $PSNR->close();
   
    my ($res_rate, $res_psnrY, $res_psnrCb, $res_psnrCr) = split ( /	/, $result );
	
    unlink $errname or die "Can not delete $errname $!";
   
   return ($res_rate, $res_psnrY, $res_psnrCb, $res_psnrCr);
}

##############################################################################
# Function         : Resize ($;$;@)
##############################################################################
sub Resize($$;@)
{
	my $param=shift;
	my $log=shift;
	my ($namein,$win,$hin,$frin,$nameout,$wout,$hout,$frout,$essopt,$nbfr,$cropfile)=@_;
	
	my $display=1;
	my $bin =$param->{path_bin};
	my $tmp =$param->{path_tmp};
	
	unless (defined $cropfile) 
	{
		if($essopt ==2)
		{ die "Cropping file is needed!\n";}
		else
		{
			$cropfile = "${tmp}tempocrop.txt";
			my $f = new IO::File $cropfile , "w";
			(defined $f) or die "- Failed to open the logfile $cropfile : $!";
			print $f "0, 0,  $win, $hin ";
			#print $f "0, 0,  $wout, $hout";
			$f->close();
		}
	}
		
	my $temporatio=GetPowerof2($frin/$frout);
	my $temporesize="${tmp}temporesize.txt";
	my $cmd ="$bin$RESAMPLER  -ess $essopt $namein $win $hin $nameout $wout $hout 0 0 0 0 $cropfile $temporatio 0 $nbfr 2> $temporesize";
	
	my $ret = run($cmd, $log,0);
	($ret == 0) or die "problem while executing the command:\n$cmd\n";  

	(-f $temporesize) and (unlink $temporesize or die" Can not remove $temporesize $!");
	($cropfile eq "${tmp}tempocrop.txt") and (-f $cropfile) and (unlink $cropfile or die" Can not remove $cropfile $!");
	  	   					         
}     					         

##############################################################################
# Function         : Resize2 ($;$;@)
##############################################################################
#very dirty
sub Resize2($$;@)
{
	my $param=shift;
	my $log=shift;
	my ($namein,$win,$hin,$frin,$nameout,$wout,$hout,$frout,$essopt,$nbfr,$cropfile)=@_;
	
	my $display=1;
	my $bin =$param->{path_bin};
	my $tmp =$param->{path_tmp};
	
	my $cmd;
	my $ret;
	my $temporatio=GetPowerof2($frin/$frout);
	($win>=$wout) or die "The input width must be greater or equal to the output width $!";
	($hin>=$hout) or die "The input height must be greater or equal to the output height $!";
		
	my $wratio=$win/$wout;
	my $hratio=$hin/$hout;
	
	my $wres=GetPowerof2($wratio);
	my $hres=GetPowerof2($hratio);
	
	if(defined $cropfile)
	{
		$cmd ="$bin$RESAMPLER  -ess $essopt $namein $win $hin $nameout $wout $hout 0 0 0 0 $cropfile $temporatio 0 $nbfr 2> ${tmp}temporesize.txt";	
		$ret = run($cmd, $log,0);
		($ret == 0) or die "problem while executing the command:\n$cmd\n";  
	}
	else
	{
		if($essopt ==2)
		{ die "Cropping file is needed!\n";}
			
		my $temporesize="${tmp}temporesize.txt";
		if ( ($wratio != $hratio) or ($wres==-1) or ($hres==-1) ) #ESS downsampling
		{
			$cropfile = "${tmp}tempocrop.txt";
			my $f = new IO::File $cropfile , "w";
			(defined $f) or die "- Failed to open the logfile $cropfile : $!";
			print $f "0, 0,  $win, $hin ";
			#print $f "0, 0,  $wout, $hout";
			$f->close();
			
			$cmd ="$bin$RESAMPLER  -ess $essopt $namein $win $hin $nameout $wout $hout 0 0 0 0 $cropfile $temporatio 0 $nbfr 2> $temporesize";
		
			$ret = run($cmd, $log,0);
			($ret == 0) or die "problem while executing the command:\n$cmd\n";  
			(-f $cropfile) and (unlink $cropfile or die "Can not remove $cropfile $!");
		}
		else
		{
			$cmd ="$bin$RESAMPLER  $win $hin $namein $wres $temporatio $nameout 0 $nbfr 2> $temporesize";
			$ret = run($cmd, $log,0);
			($ret == 0) or die "problem while executing the command:\n$cmd\n";  
		}
		(-f $temporesize) and (unlink $temporesize or die" Can not remove $temporesize $!");
		
	}  	   					         
} 



#########################################################################
#Dirty
sub GetPowerof2
    {
	my $val=shift;

        ($val <1) and return -1;
	($val == 1) and return 0;
    
        my $exp = 0 ;
    
        while (!($val & 1))
        {
            $val>>=1; 
            $exp++ ;
        }

        (($val == 1) && ($exp != 0)) and return $exp ;

        return -1 ;
    }



1;
__END__