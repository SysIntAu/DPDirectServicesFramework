package org.dpdirect.batchvalidator;

/**
 * A simple interface to handle validation errors at a batch level.
 * 
 * @author N.A.
 */
public interface ValidationErrorHandler {

	/**
	 * Handles a validation error.
	 * 
	 * @param msg
	 *            a text message with details of the validation error.
	 */
	public void handleValidationError(String msg);

}