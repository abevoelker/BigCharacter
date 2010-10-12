
 /*------------------------------------------------------------------------
    File        : BigCharacter.cls
    Purpose     : Mimics LONGCHAR, but removes performance penalties.
    Author(s)   : Abe Voelker
    Created     : Mon Oct 04 19:45:25 CDT 2010
    Notes       : * This version can run out of local buffer space for very
                    large amounts of data ("increase -l" error messages).
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS BigCharacter USE-WIDGET-POOL:

    &SCOPED-DEFINE CHARACTER_DATATYPE_MAX 31991

    DEFINE PRIVATE VARIABLE iMaxBlocks AS INTEGER NO-UNDO. /* Max number of CharBlocks */
    DEFINE PRIVATE VARIABLE iNumBlocks AS INTEGER NO-UNDO.

    DEFINE PRIVATE TEMP-TABLE ttBlock NO-UNDO
      FIELD iPK      AS INTEGER
      FIELD objBlock AS Object
      INDEX IXPK IS PRIMARY UNIQUE iPK.
		
    CONSTRUCTOR PUBLIC BigCharacter ():
		SUPER().
		iMaxBlocks = 500. /* Default */
		CREATE ttBlock.
		ASSIGN iNumBlocks       = 1
		       ttBlock.objBlock = NEW CharBlock(THIS-OBJECT)
		       ttBlock.iPK      = iNumBlocks.
	END CONSTRUCTOR.
		
	CONSTRUCTOR PUBLIC BigCharacter (INPUT ipiMaxBlocks AS INTEGER):
		SUPER().
		iMaxBlocks = ipiMaxBlocks.
		CREATE ttBlock.
		ASSIGN iNumBlocks       = 1
		       ttBlock.objBlock = NEW CharBlock(THIS-OBJECT)
		       ttBlock.iPK      = iNumBlocks.
	END CONSTRUCTOR.
	
    METHOD PUBLIC VOID empty():
        FOR EACH ttBlock:
            IF VALID-OBJECT(ttBlock.objBlock) THEN
                DELETE OBJECT ttBlock.objBlock NO-ERROR.
        END.
	    EMPTY TEMP-TABLE ttBlock NO-ERROR.
	    CREATE ttBlock.
	    ASSIGN iNumBlocks       = 1
		       ttBlock.objBlock = NEW CharBlock(THIS-OBJECT)
		       ttBlock.iPK      = iNumBlocks.
	END METHOD.
    
	METHOD PUBLIC VOID append(INPUT ipc AS CHARACTER):
	    FIND LAST ttBlock.
	    
	    IF CAST(ttBlock.objBlock, CharBlock):getNumBlocks() GE iMaxBlocks THEN DO:
	        CREATE ttBlock.
	        ASSIGN iNumBlocks       = iNumBlocks + 1
	               ttBlock.objBlock = NEW CharBlock(THIS-OBJECT)
	               ttBlock.iPK      = iNumBlocks.
	    END.
	    
	    CAST(ttBlock.objBlock, CharBlock):append(ipc).
    END METHOD.
    
    METHOD PUBLIC VOID append(INPUT iplc AS LONGCHAR):
        FIND LAST ttBlock.
	    
	    IF CAST(ttBlock.objBlock, CharBlock):getNumBlocks() GE iMaxBlocks THEN DO:
	        CREATE ttBlock.
	        ASSIGN iNumBlocks       = iNumBlocks + 1
	               ttBlock.objBlock = NEW CharBlock(THIS-OBJECT)
	               ttBlock.iPK      = iNumBlocks.
	    END.
	    
	    CAST(ttBlock.objBlock, CharBlock):append(iplc).
    END METHOD.
    
    METHOD PUBLIC VOID append(INPUT ipobjbc AS BigCharacter):
        DEF VAR i AS INT NO-UNDO.
        
        FIND LAST ttBlock.
	    DO i=1 TO ipobjbc:getNumBlocks():
    	    IF CAST(ttBlock.objBlock, CharBlock):getNumBlocks() GE iMaxBlocks THEN DO:
    	        CREATE ttBlock.
    	        ASSIGN iNumBlocks       = iNumBlocks + 1
    	               ttBlock.objBlock = NEW CharBlock(THIS-OBJECT)
    	               ttBlock.iPK      = iNumBlocks.
    	    END.
    	    CAST(ttBlock.objBlock, CharBlock):append(ipobjbc:getCharBlock(i)).
	    END.
    END METHOD.
    
    METHOD PUBLIC VOID setValue(INPUT ipcString AS CHARACTER):
        THIS-OBJECT:empty().
        THIS-OBJECT:append(ipcString).
    END.
    
    METHOD PUBLIC VOID setValue(INPUT iplcString AS LONGCHAR):
        THIS-OBJECT:empty().
        THIS-OBJECT:append(iplcString).
    END.
    
    METHOD PUBLIC VOID setValue(INPUT ipobjbc AS BigCharacter):
        THIS-OBJECT:empty().
        THIS-OBJECT:append(ipobjbc).
    END.
    
	METHOD PUBLIC INTEGER indexOf(INPUT ipcString   AS CHARACTER):
	    RETURN INDEX(THIS-OBJECT:toLongchar(), ipcString).
	END METHOD.
	
	METHOD PUBLIC INTEGER indexOf(INPUT ipcString   AS CHARACTER,
	                              INPUT ipiStarting AS INTEGER):
	    RETURN INDEX(THIS-OBJECT:toLongchar(), ipcString, ipiStarting).
	END METHOD.
    
	METHOD PUBLIC BigCharacter substr(INPUT ipiPosition AS INTEGER):
	    DEFINE VARIABLE obj AS BigCharacter NO-UNDO.
	    obj:append(SUBSTRING(THIS-OBJECT:toLongchar(), ipiPosition)).
	    RETURN obj.
	END.
	
	METHOD PUBLIC BigCharacter substr(INPUT ipiPosition AS INTEGER,
	                              INPUT ipiLength   AS INTEGER):
	    DEFINE VARIABLE obj AS BigCharacter NO-UNDO.
	    obj:append(SUBSTRING(THIS-OBJECT:toLongchar(), ipiPosition, ipiLength)).
	    RETURN obj.
	END.
    
    METHOD PUBLIC LONGCHAR toLongchar():
        DEFINE VARIABLE oplc AS LONGCHAR NO-UNDO.
        FOR EACH ttBlock:
          oplc = oplc + CAST(ttBlock.objBlock, CharBlock):toLongchar().
        END.
        RETURN oplc.
    END METHOD.
    
    /* Note: If too much data to fit in a CHAR, method will return ? */
    METHOD PUBLIC CHARACTER toChar():
        DEFINE VARIABLE opc   AS CHARACTER        NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   INIT 1 NO-UNDO.
        DEFINE VARIABLE iSize AS INTEGER          NO-UNDO.
        
        FOR EACH ttBlock:
            iSize = iSize + CAST(ttBlock.objBlock, CharBlock):size().
            IF iSize GT {&CHARACTER_DATATYPE_MAX} THEN
                RETURN ?.
            ELSE
                opc = opc + CAST(ttBlock.objBlock, CharBlock):getBlock(i).
            i = i + 1.
        END.
        RETURN opc.
    END METHOD.
    
    METHOD PUBLIC LOGICAL toFile(INPUT ipcFile AS CHARACTER,
                                 INPUT iplAppend AS LOGICAL):
        IF NOT iplAppend THEN
            OS-DELETE VALUE(ipcFile).
        FOR EACH ttBlock:
            IF NOT CAST(ttBlock.objBlock, CharBlock):toFile(ipcFile, TRUE) THEN
                RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.
    
    METHOD PUBLIC LOGICAL toFile(INPUT ipcFile AS CHARACTER):
        RETURN THIS-OBJECT:toFile(ipcFile, FALSE). /* Default is to clobber the old file */
    END METHOD.
    
    METHOD PUBLIC INT64 size():
        DEFINE VARIABLE iTotBlockSize AS INT64 NO-UNDO.
        FOR EACH ttBlock:
            iTotBlockSize = iTotBlockSize + CAST(ttBlock.objBlock, CharBlock):size().
        END.
        RETURN iTotBlockSize.
    END.
    
    /* Progress epic-fails when the below method is set to PRIVATE or PROTECTED */
    METHOD PUBLIC INTEGER getNumBlocks():
        RETURN iNumBlocks.
    END METHOD.
    
    /* Progress epic-fails when the below method is set to PRIVATE or PROTECTED */
    METHOD PUBLIC CharBlock getCharBlock(INPUT ipiCharBlockNum AS INTEGER):
        FIND FIRST ttBlock WHERE ttBlock.iPK EQ ipiCharBlockNum NO-ERROR.
        IF AVAILABLE ttBlock THEN
            RETURN CAST(ttBlock.objBlock, CharBlock).
        ELSE
            RETURN ?.
    END METHOD.

END CLASS.