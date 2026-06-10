package com.blkn.lr.lr_new_server.exception;

public class FileEmptyException extends FileUploadException {

	private static final long serialVersionUID = 1L;

	public FileEmptyException() {
		super();
	}

	public FileEmptyException(String arg0, Throwable arg1, boolean arg2, boolean arg3) {
		super(arg0, arg1, arg2, arg3);
	}

	public FileEmptyException(String arg0, Throwable arg1) {
		super(arg0, arg1);
	}

	public FileEmptyException(String arg0) {
		super(arg0);
	}

	public FileEmptyException(Throwable arg0) {
		super(arg0);
	}
	
	
}
