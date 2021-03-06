package edu.neu.csye6225.spring19.cloudninja.util;

import java.text.SimpleDateFormat;
import java.util.Date;

import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;

@Component
@Scope(value = "singleton")
public class CommonUtil {

	public String getCurrentDateWithFormat(String format) {

		SimpleDateFormat simpleDateFormat = new SimpleDateFormat(format);
		return simpleDateFormat.format(new Date());
	}

	public String getFileNameFromPath(String path) {
		String[] pathArr = path.split("/");
		return pathArr[pathArr.length - 1];
	}

	public String stackTraceString(Exception e) {
		StringBuffer sb = new StringBuffer();

		// Main stacktrace
		StackTraceElement[] stack = e.getStackTrace();
		stackTraceStringBuffer(sb, e.toString(), stack, 0);

		// The cause(s)
		Throwable cause = e.getCause();
		while (cause != null) {
			// Cause start first line
			sb.append("Caused by: ");

			// Cause stacktrace
			StackTraceElement[] parentStack = stack;
			stack = cause.getStackTrace();
			if (parentStack == null || parentStack.length == 0)
				stackTraceStringBuffer(sb, cause.toString(), stack, 0);
			else {
				int equal = 0; // Count how many of the last stack frames are equal
				int frame = stack.length - 1;
				int parentFrame = parentStack.length - 1;
				while (frame > 0 && parentFrame > 0) {
					if (stack[frame].equals(parentStack[parentFrame])) {
						equal++;
						frame--;
						parentFrame--;
					} else
						break;
				}
				stackTraceStringBuffer(sb, cause.toString(), stack, equal);
			}
			cause = cause.getCause();
		}

		return sb.toString();
	}

	// Adds to the given StringBuffer a line containing the name and
	// all stacktrace elements minus the last equal ones.
	public static void stackTraceStringBuffer(StringBuffer sb, String name, StackTraceElement[] stack, int equal) {
		String nl = System.getProperty("line.separator");
		// (finish) first line
		sb.append(name);
		sb.append(nl);

		// The stacktrace
		if (stack == null || stack.length == 0) {
			sb.append("   <<No stacktrace available>>");
			sb.append(nl);
		} else {
			for (int i = 0; i < stack.length - equal; i++) {
				sb.append("   at ");
				sb.append(stack[i] == null ? "<<Unknown>>" : stack[i].toString());
				sb.append(nl);
			}
			if (equal > 0) {
				sb.append("   ...");
				sb.append(equal);
				sb.append(" more");
				sb.append(nl);
			}
		}
	}
}
