package org.dpdirect.batchvalidator;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.PrintWriter;

import org.dpdirect.commons.DirectoryFilter;
import org.dpdirect.commons.FilePatternFilter;
import org.dpdirect.commons.TextAppender;

/**
 * A batch validation utility class which recursively validates all files of a
 * certain type in a file-system tree.
 * 
 * @author N.A.
 */
public class BatchValidator implements ValidationErrorHandler {

	/**
	 * The header string used to start error messages in the output report.
	 */
	protected static final String ERROR_MSG_HEADER = "-------------- Error Messages ${file.type} ---------------";

	/**
	 * The header string used to start the results summary in the output report.
	 */
	protected static final String RESULTS_SUMMARY_HEADER = "-------------- Results Summary ${file.type} --------------";

	/**
	 * The root directory from which to search.
	 */
	protected String rootDirectory = null;

	/**
	 * Count of files processed.
	 */
	protected int fileCount = 0;

	/**
	 * Count of files that passed validation.
	 */
	protected int passedCount = 0;

	/**
	 * Count of files that failed validation.
	 */
	protected int failedCount = 0;

	/**
	 * Buffer to temporarily store error messages for each invocation of the
	 * <code>run()</code> method.
	 */
	protected StringBuffer errorMsgBuffer = null;

	/**
	 * File validator for a specific file/grammar type.
	 */
	protected FileValidator fileValidator = null;

	/**
	 * Constructs a new <code>BatchValidator</code> object.
	 * 
	 * @param rootDirectory
	 *            the root directory from which to search.
	 */
	public BatchValidator(String rootDirectory, FileValidator fileValidator) {
		this.rootDirectory = rootDirectory;
		this.fileValidator = fileValidator;
	}

	/**
	 * Runs the recursive validation operation and returns a summary of the
	 * results.
	 * 
	 * @param textAppender
	 *            an appender to accept output text.
	 * 
	 * @return a summary of the results.
	 */
	public void run(TextAppender textAppender) {
		// Check that the rootDirectory is a valid directory.
		File rootDir = new File(rootDirectory);
		if (!rootDir.isDirectory()) {
			throw new RuntimeException("Root directory is not a directory.");
		}

		// Recursively process the directory.
		process(rootDir, textAppender);

	}

	/**
	 * Prints a summary of the validation results.
	 * 
	 * @param textAppender
	 *            an appender to accept output text.
	 * 
	 * @return a summary of the results.
	 */
	public void printSummary(TextAppender textAppender) {
		// Append summary information to the buffer.
		textAppender.appendOutputText("\n"
				+ RESULTS_SUMMARY_HEADER.replaceAll("\\$\\{file.type\\}", " [ "
						+ fileValidator.getFileTypeDescription() + " files ] ")
				+ "\n");
		textAppender.appendOutputText("Processed " + fileCount + " files.\n");
		textAppender.appendOutputText("Passed  count = " + passedCount + "\n");
		textAppender.appendOutputText("Failed  count = " + failedCount + "\n");
	}

	/**
	 * Prints details of the validation errors.
	 * 
	 * @param textAppender
	 *            an appender to accept output text.
	 * 
	 * @return a summary of the results.
	 */
	public void printErrors(TextAppender textAppender) {
		// Append error messages if there are any
		if (null != errorMsgBuffer && 0 < errorMsgBuffer.length()) {
			textAppender.appendOutputText("\n"
					+ ERROR_MSG_HEADER.replaceAll("\\$\\{file.type\\}", " [ "
							+ fileValidator.getFileTypeDescription()
							+ " files ] ") + "\n");
			textAppender.appendOutputText(errorMsgBuffer.toString());
		}
	}

	/**
	 * Recursively processes directories and files.
	 * <p>
	 * For directories it processes each file (with given extension) and
	 * recursively processes each subdirectory.
	 * </p>
	 * <p>
	 * For files it evaluates the XPath on the file infoset and appends result
	 * messages to the <code>TextAppender</code> object.
	 * </p>
	 * 
	 * @param file
	 *            the file or directory to process.
	 * 
	 * @param textAppender
	 *            an appender to accept output text.
	 */
	private void process(File file, TextAppender textAppender) {
		if (file.isDirectory()) {
			// Get all files with given extension and process.
			File[] files = file.listFiles(new FilePatternFilter(fileValidator
					.getFilenameFilterPattern()));
			if (null != files) {
				for (int i = 0; i < files.length; i++) {
					process(files[i], textAppender);
				}
			}
			// Get all directories and recursively process.
			File[] dirs = file.listFiles(new DirectoryFilter());
			if (null != dirs) {
				for (int i = 0; i < dirs.length; i++) {
					process(dirs[i], textAppender);
				}
			}
		} else {
			fileCount++;
			try {
				fileValidator.validate(file);
				textAppender.appendOutputText("[" + ++passedCount + "] ");
				textAppender.appendOutputText(file.getAbsolutePath()
						+ " [PASSED]\n");
			} catch (Exception e) {
				textAppender.appendOutputText("[" + ++failedCount + "] ");
				textAppender.appendOutputText(file.getAbsolutePath()
						+ " [FAILED]\n");
				// Write the stack trace to an output stream.
				ByteArrayOutputStream baos = new ByteArrayOutputStream();
				PrintWriter w = new PrintWriter(baos, true);
				e.printStackTrace(w);
				handleValidationError(new String(baos.toByteArray())
						.split("\n")[0]);
			}
		}

	}

	/**
	 * Handles a validation error.
	 * 
	 * @param msg
	 *            a text message with details of the validation error.
	 */
	@Override
	public void handleValidationError(String msg) {
		if (null == errorMsgBuffer) {
			errorMsgBuffer = new StringBuffer("");
		}
		errorMsgBuffer.append("\n").append(msg).append("\n");
	}

}
