package com.blkn.lr.lr_new_server.util;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;
import lombok.AllArgsConstructor;

/**
 * self-defined data type as a tool of data transform 
 *
 * @param <T>
 */
@AllArgsConstructor
public class JsonResult<T> {
	
//	@JsonInclude(value=Include.ALWAYS)
//	private Integer state;
	@JsonInclude(value=Include.NON_NULL)
	private String message;
	@JsonInclude(value=Include.ALWAYS)
	private T data;
}
