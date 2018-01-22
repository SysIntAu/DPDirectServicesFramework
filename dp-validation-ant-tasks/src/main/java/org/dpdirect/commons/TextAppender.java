package org.dpdirect.commons;

/**
 * An Interface for appending output text (typically to a user interface while
 * some processing tasks are in progress).
 * 
 * @author N.A..
 * 
 */
public interface TextAppender {

	/**
	 * Clears output text.
	 */
	public void clearOutputText();

	/**
	 * Appends output text.
	 * 
	 * @param text
	 *            the text to append.
	 */
	public void appendOutputText(String text);

	/**
	 * Indicates that the final text has been appended for a given atomic
	 * process.
	 */
	public void finaliseOutputText();

}
