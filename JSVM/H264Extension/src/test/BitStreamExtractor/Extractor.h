/*
********************************************************************************

NOTE - One of the two copyright statements below may be chosen
       that applies for the software.

********************************************************************************

This software module was originally developed by

Heiko Schwarz    (Fraunhofer HHI),
Tobias Hinz      (Fraunhofer HHI),
Karsten Suehring (Fraunhofer HHI)

in the course of development of the ISO/IEC 14496-10:2005 Amd.1 (Scalable Video
Coding) for reference purposes and its performance may not have been optimized.
This software module is an implementation of one or more tools as specified by
the ISO/IEC 14496-10:2005 Amd.1 (Scalable Video Coding).

Those intending to use this software module in products are advised that its
use may infringe existing patents. ISO/IEC have no liability for use of this
software module or modifications thereof.

Assurance that the originally developed software module can be used
(1) in the ISO/IEC 14496-10:2005 Amd.1 (Scalable Video Coding) once the
ISO/IEC 14496-10:2005 Amd.1 (Scalable Video Coding) has been adopted; and
(2) to develop the ISO/IEC 14496-10:2005 Amd.1 (Scalable Video Coding): 

To the extent that Fraunhofer HHI owns patent rights that would be required to
make, use, or sell the originally developed software module or portions thereof
included in the ISO/IEC 14496-10:2005 Amd.1 (Scalable Video Coding) in a
conforming product, Fraunhofer HHI will assure the ISO/IEC that it is willing
to negotiate licenses under reasonable and non-discriminatory terms and
conditions with applicants throughout the world.

Fraunhofer HHI retains full right to modify and use the code for its own
purpose, assign or donate the code to a third party and to inhibit third
parties from using the code for products that do not conform to MPEG-related
ITU Recommendations and/or ISO/IEC International Standards. 

This copyright notice must be included in all copies or derivative works.
Copyright (c) ISO/IEC 2005. 

********************************************************************************

COPYRIGHT AND WARRANTY INFORMATION

Copyright 2005, International Telecommunications Union, Geneva

The Fraunhofer HHI hereby donate this source code to the ITU, with the following
understanding:
    1. Fraunhofer HHI retain the right to do whatever they wish with the
       contributed source code, without limit.
    2. Fraunhofer HHI retain full patent rights (if any exist) in the technical
       content of techniques and algorithms herein.
    3. The ITU shall make this code available to anyone, free of license or
       royalty fees.

DISCLAIMER OF WARRANTY

These software programs are available to the user without any license fee or
royalty on an "as is" basis. The ITU disclaims any and all warranties, whether
express, implied, or statutory, including any implied warranties of
merchantability or of fitness for a particular purpose. In no event shall the
contributor or the ITU be liable for any incidental, punitive, or consequential
damages of any kind whatsoever arising from the use of these programs.

This disclaimer of warranty extends to the user of these programs and user's
customers, employees, agents, transferees, successors, and assigns.

The ITU does not represent or warrant that the programs furnished hereunder are
free of infringement of any third-party patents. Commercial implementations of
ITU-T Recommendations, including shareware, may be subject to royalty fees to
patent holders. Information regarding the ITU-T patent policy is available from 
the ITU Web site at http://www.itu.int.

THIS IS NOT A GRANT OF PATENT RIGHTS - SEE THE ITU-T PATENT POLICY.

********************************************************************************
*/




#ifndef __EXTRACTOR_H_D65BE9B4_A8DA_11D3_AFE7_005004464B79
#define __EXTRACTOR_H_D65BE9B4_A8DA_11D3_AFE7_005004464B79


#define MAX_PACKET_SIZE 1000000


#include "H264AVCCommonLib/Sei.h"

#include "ReadBitstreamFile.h"
#include "WriteBitstreamToFile.h"
#include "ExtractorParameter.h"


class ScalableStreamDescription
{
public:
  ScalableStreamDescription   ();
  ~ScalableStreamDescription  ();

  ErrVal  init      ( h264::SEI::ScalableSei* pcScalableSei );
  ErrVal  uninit    ();
  ErrVal  addPacket ( UInt                    uiNumBytes,
                      UInt                    uiLayer,
                      UInt                    uiLevel,
                      UInt                    uiFGSLayer,
                      Bool                    bNewPicture );
  ErrVal  analyse   ();
  Void    output    ( FILE*                   pFile );

  UInt    getNumberOfLayers ()                  const { return m_uiNumLayers; }
  UInt    getFrameWidth     ( UInt uiLayer )    const { return m_auiFrameWidth  [uiLayer]; }
  UInt    getFrameHeight    ( UInt uiLayer )    const { return m_auiFrameHeight [uiLayer]; }
  UInt    getMaxLevel       ( UInt uiLayer )    const { return m_auiDecStages   [uiLayer]; }
  Double  getFrameRateUnit  ()                  const { return (Double)m_uiFrameRateUnitNom/(Double)m_uiFrameRateUnitDenom; }
  UInt    getNumPictures    ( UInt uiLayer,
                              UInt uiLevel )    const { return m_aauiNumPictures[uiLayer][uiLevel]; }
  UInt64  getNALUBytes      ( UInt uiLayer,
                              UInt uiLevel,
                              UInt uiFGS   )    const { return m_aaaui64NumNALUBytes[uiLayer][uiLevel][uiFGS]; }
 

private:
  Bool    m_bInit;
  Bool    m_bAnalyzed;
  
  UInt    m_uiNumLayers;
  Bool    m_bAVCBaseLayer;
  UInt    m_uiAVCTempResStages;
  UInt    m_uiFrameRateUnitDenom;
  UInt    m_uiFrameRateUnitNom;
  UInt    m_uiMaxDecStages;
  UInt    m_auiFrameWidth       [MAX_LAYERS];
  UInt    m_auiFrameHeight      [MAX_LAYERS];
  UInt    m_auiDecStages        [MAX_LAYERS];

  UInt64  m_aaaui64NumNALUBytes [MAX_LAYERS][MAX_DSTAGES+1][MAX_FGS_LAYERS];
  UInt64  m_aaui64BaseLayerBytes[MAX_LAYERS][MAX_DSTAGES+1];
  UInt64  m_aaui64FGSLayerBytes [MAX_LAYERS][MAX_DSTAGES+1];
  UInt    m_aauiNumPictures     [MAX_LAYERS][MAX_DSTAGES+1];
};



class Extractor  
{
protected:
	Extractor();
	virtual ~Extractor();

public:
  static ErrVal create              ( Extractor*&         rpcExtractor );
  ErrVal        init                ( ExtractorParameter* pcExtractorParameter );
  ErrVal        go                  ();
  ErrVal        destroy             ();

protected:
  ErrVal        xAnalyse            ();
  ErrVal        xSetParameters      ();
  ErrVal        xExtractPoints      ();
  ErrVal        xExtractLayerLevel  ();

protected:
  ReadBitstreamIf*              m_pcReadBitstream;
  WriteBitstreamIf*             m_pcWriteBitstream;
  ExtractorParameter*           m_pcExtractorParameter;
  h264::H264AVCPacketAnalyzer*  m_pcH264AVCPacketAnalyzer;

  UChar                         m_aucStartCodeBuffer[5];
  BinData                       m_cBinDataStartCode;

  ScalableStreamDescription     m_cScalableStreamDescription;
  Double                        m_aadTargetSNRLayer[MAX_LAYERS][MAX_DSTAGES+1];
};

#endif //__EXTRACTOR_H_D65BE9B4_A8DA_11D3_AFE7_005004464B79
