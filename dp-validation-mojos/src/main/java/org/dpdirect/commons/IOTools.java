package org.dpdirect.commons;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * A collection of utility methods to facilitate common I/O operations.
 * 
 * @author N.A.
 * 
 */
public class IOTools {

	/**
	 * Reads the byte content of an <code>InputStream</code>.
	 * 
	 * @param inputStream
	 *            the <code>InputStream</code> of which to get the content
	 * 
	 * @return the byte content of the <code>InputStream</code>
	 * 
	 * @exception IOException
	 *                if there is an error reading the <code>InputStream</code>
	 */
	public static byte[] readInputStreamBytes(InputStream inputStream)
			throws IOException {
		final byte[] bytes;

		ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
		try {
			byte[] buffer = new byte[4096];
			int bytesRead = inputStream.read(buffer);
			while (bytesRead != -1) {
				outputStream.write(buffer, 0, bytesRead);
				bytesRead = inputStream.read(buffer);
			}
			bytes = outputStream.toByteArray();
		} finally {
			outputStream.close();
		}

		return bytes;
	}

}
