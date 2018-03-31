package org.dpdirect.batchvalidator;

import java.io.File;

/**
 * An interface to represent file validation for specific file/grammar types.
 * 
 * @author N.A.
 */
public interface FileValidator {

	/**
	 * Validates a single file.
	 * 
	 * @param file
	 *            the file to validate.
	 * 
	 * @throws Exception
	 *             if there is a validation error.
	 */
	public void validate(File file) throws Exception;

	/**
	 * Gets a short description of the type of file that is being validated.
	 * 
	 * @return a short description of the type of file that is being validated.
	 */
	public String getFileTypeDescription();

	/**
	 * Gets a regular expression that represents the allowable types of file
	 * names for a specific file/grammar type. E.g. ".*\\.(xsl|xslt)"
	 * 
	 * @return a regular expression that represents the allowable types of file
	 *         names for a specific file/grammar type.
	 */
	public String getFilenameFilterPattern();

	/**
	 * Sets an error handler.
	 * 
	 * @param errorHandler
	 *            the error handler to set.
	 */
	public void setValidationErrorHandler(ValidationErrorHandler errorHandler);

}
