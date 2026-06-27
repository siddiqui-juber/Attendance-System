package com.Genxcraft.Backend.dto;

import lombok.*;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsResponse {
    private long totalStudents;
    private long totalTeachers;
    private long totalBranches;
    private long totalBatches;
    private long todayPresentCount;
    private long todayAbsentCount;
    private double todayAttendancePercentage;
    // Map of dates to present/absent count for graphs
    private Map<String, Long> weeklyPresentStats;
    private Map<String, Long> weeklyAbsentStats;
}
