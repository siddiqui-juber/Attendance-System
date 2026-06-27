package com.Genxcraft.Backend.service;

import com.Genxcraft.Backend.entity.Attendance;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;
import java.util.List;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class ReportService {

    public byte[] generateExcelReport(List<Attendance> attendanceList, String title) throws IOException {

        try (Workbook workbook = new XSSFWorkbook()) {

            Sheet sheet = workbook.createSheet("Attendance Report");

            // Title Row
            Row titleRow = sheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue(title);

            CellStyle titleStyle = workbook.createCellStyle();
            org.apache.poi.ss.usermodel.Font titleFont = workbook.createFont();
            titleFont.setBold(true);
            titleFont.setFontHeightInPoints((short) 14);
            titleStyle.setFont(titleFont);
            titleCell.setCellStyle(titleStyle);

            // Header Row
            Row headerRow = sheet.createRow(2);

            String[] columns = {
                    "ID",
                    "Student Name",
                    "Roll Number",
                    "Class",
                    "Batch",
                    "Date",
                    "Time",
                    "Status",
                    "Teacher"
            };

            CellStyle headerStyle = workbook.createCellStyle();

            org.apache.poi.ss.usermodel.Font headerFont = workbook.createFont();
            headerFont.setBold(true);

            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(
                    IndexedColors.GREY_25_PERCENT.getIndex()
            );
            headerStyle.setFillPattern(
                    FillPatternType.SOLID_FOREGROUND
            );

            for (int i = 0; i < columns.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowNum = 3;

            DateTimeFormatter dateFormatter =
                    DateTimeFormatter.ofPattern("dd/MM/yyyy");

            DateTimeFormatter timeFormatter =
                    DateTimeFormatter.ofPattern("HH:mm");

            for (Attendance att : attendanceList) {

                Row row = sheet.createRow(rowNum++);

                row.createCell(0).setCellValue(att.getStudent().getStudentId());
                row.createCell(1).setCellValue(att.getStudent().getName());
                row.createCell(2).setCellValue(att.getStudent().getRollNumber());
                row.createCell(3).setCellValue(att.getStudent().getClazz().getName());
                row.createCell(4).setCellValue(att.getStudent().getBatch().getName());
                row.createCell(5).setCellValue(att.getDate().format(dateFormatter));
                row.createCell(6).setCellValue(att.getTime().format(timeFormatter));
                row.createCell(7).setCellValue(att.getStatus().name());
                row.createCell(8).setCellValue(att.getTeacher().getName());
            }

            for (int i = 0; i < columns.length; i++) {
                sheet.autoSizeColumn(i);
            }

            ByteArrayOutputStream outputStream =
                    new ByteArrayOutputStream();

            workbook.write(outputStream);

            return outputStream.toByteArray();
        }
    }

    public byte[] generatePdfReport(List<Attendance> attendanceList, String title) {

        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

        try {

            PdfWriter.getInstance(document, outputStream);

            document.open();

            com.lowagie.text.Font titleFont =
                    FontFactory.getFont(
                            FontFactory.HELVETICA_BOLD,
                            18,
                            Color.BLACK
                    );

            Paragraph titleParagraph =
                    new Paragraph(title, titleFont);

            titleParagraph.setAlignment(Element.ALIGN_CENTER);
            titleParagraph.setSpacingAfter(20);

            document.add(titleParagraph);

            PdfPTable table = new PdfPTable(8);

            table.setWidthPercentage(100);

            table.setWidths(new float[]{
                    1.2f,
                    2.0f,
                    1.0f,
                    1.2f,
                    1.2f,
                    1.2f,
                    1.0f,
                    1.2f
            });

            String[] headers = {
                    "Stu ID",
                    "Student Name",
                    "Roll No",
                    "Class",
                    "Batch",
                    "Date",
                    "Status",
                    "Teacher"
            };

            com.lowagie.text.Font pdfHeaderFont =
                    FontFactory.getFont(
                            FontFactory.HELVETICA_BOLD,
                            10,
                            Color.WHITE
                    );

            for (String colHeader : headers) {

                PdfPCell headerCell =
                        new PdfPCell(new Phrase(colHeader, pdfHeaderFont));

                headerCell.setBackgroundColor(new Color(63, 81, 181));
                headerCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                headerCell.setPadding(6);

                table.addCell(headerCell);
            }

            com.lowagie.text.Font dataFont =
                    FontFactory.getFont(
                            FontFactory.HELVETICA,
                            9,
                            Color.BLACK
                    );

            DateTimeFormatter dateFormatter =
                    DateTimeFormatter.ofPattern("dd/MM/yyyy");

            for (Attendance att : attendanceList) {

                table.addCell(new PdfPCell(
                        new Phrase(att.getStudent().getStudentId(), dataFont)));

                table.addCell(new PdfPCell(
                        new Phrase(att.getStudent().getName(), dataFont)));

                table.addCell(new PdfPCell(
                        new Phrase(att.getStudent().getRollNumber(), dataFont)));

                table.addCell(new PdfPCell(
                        new Phrase(att.getStudent().getClazz().getName(), dataFont)));

                table.addCell(new PdfPCell(
                        new Phrase(att.getStudent().getBatch().getName(), dataFont)));

                table.addCell(new PdfPCell(
                        new Phrase(att.getDate().format(dateFormatter), dataFont)));

                PdfPCell statusCell =
                        new PdfPCell(new Phrase(att.getStatus().name(), dataFont));

                if ("PRESENT".equals(att.getStatus().name())) {
                    statusCell.setBackgroundColor(new Color(232, 245, 233));
                } else {
                    statusCell.setBackgroundColor(new Color(255, 235, 235));
                }

                table.addCell(statusCell);

                table.addCell(new PdfPCell(
                        new Phrase(att.getTeacher().getName(), dataFont)));
            }

            document.add(table);

            document.close();

        } catch (Exception e) {
            throw new RuntimeException("Could not generate PDF report", e);
        }

        return outputStream.toByteArray();
    }
}