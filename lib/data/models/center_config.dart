class CenterConfig {
  final bool learnerCanCreateSession;
  final bool teacherCanCreateSession;
  final bool shareSessionsWithTeachers;
  final bool shareSessionsWithLearners;
  final bool learnerCanAccessExamPage;
  final bool teacherCanAccessExamPage;
  final bool enableJoinRequests;
  final bool autoApproveLearners;
  final bool autoApproveInstructors;
  final bool allowLearnerStoryBuilder;
  final bool allowTeacherToManageLearners;
  final bool examVisibleToLearnersAfterSessionDone;
  final bool sessionApprovalRequiredForTeachers;
  final int maxSessionsPerLearner;
  final int maxSessionsPerTeacher;
  final bool showLeaderboardToLearners;
  final bool enableGamification;
  final bool allowTeacherToCreateExams;
  final bool allowLearnerToTakeSelfQuiz;
  final bool enableFeedbackOnSessions;
  final bool allowTeachersToShareMaterials;
  final bool allowLearnersToComment;
  final bool trackSessionAttendance;
  final bool centerPubliclyVisible;
  final bool allowManualGrading;
  final bool dailyStudyReminderEnabled;
  final bool showInstructorNamesToLearners;
  final String centerLanguage;
  final bool allowMultipleRolesPerUser;
  final bool allowStudentToInvite;
  final String sessionSorting;

  const CenterConfig({
    this.learnerCanCreateSession = false,
    this.teacherCanCreateSession = true,
    this.shareSessionsWithTeachers = true,
    this.shareSessionsWithLearners = true,
    this.learnerCanAccessExamPage = false,
    this.teacherCanAccessExamPage = true,
    this.enableJoinRequests = true,
    this.autoApproveLearners = false,
    this.autoApproveInstructors = false,
    this.allowLearnerStoryBuilder = true,
    this.allowTeacherToManageLearners = true,
    this.examVisibleToLearnersAfterSessionDone = false,
    this.sessionApprovalRequiredForTeachers = false,
    this.maxSessionsPerLearner = 10,
    this.maxSessionsPerTeacher = 50,
    this.showLeaderboardToLearners = true,
    this.enableGamification = true,
    this.allowTeacherToCreateExams = true,
    this.allowLearnerToTakeSelfQuiz = true,
    this.enableFeedbackOnSessions = false,
    this.allowTeachersToShareMaterials = true,
    this.allowLearnersToComment = false,
    this.trackSessionAttendance = true,
    this.centerPubliclyVisible = false,
    this.allowManualGrading = true,
    this.dailyStudyReminderEnabled = false,
    this.showInstructorNamesToLearners = true,
    this.centerLanguage = 'en',
    this.allowMultipleRolesPerUser = false,
    this.allowStudentToInvite = false,
    this.sessionSorting = 'recent',
  });

  factory CenterConfig.fromMap(Map<String, dynamic> map) {
    return CenterConfig(
      learnerCanCreateSession: map['learnerCanCreateSession'] ?? false,
      teacherCanCreateSession: map['teacherCanCreateSession'] ?? true,
      shareSessionsWithTeachers: map['shareSessionsWithTeachers'] ?? true,
      shareSessionsWithLearners: map['shareSessionsWithLearners'] ?? true,
      learnerCanAccessExamPage: map['learnerCanAccessExamPage'] ?? false,
      teacherCanAccessExamPage: map['teacherCanAccessExamPage'] ?? true,
      enableJoinRequests: map['enableJoinRequests'] ?? true,
      autoApproveLearners: map['autoApproveLearners'] ?? false,
      autoApproveInstructors: map['autoApproveInstructors'] ?? false,
      allowLearnerStoryBuilder: map['allowLearnerStoryBuilder'] ?? true,
      allowTeacherToManageLearners: map['allowTeacherToManageLearners'] ?? true,
      examVisibleToLearnersAfterSessionDone: map['examVisibleToLearnersAfterSessionDone'] ?? false,
      sessionApprovalRequiredForTeachers: map['sessionApprovalRequiredForTeachers'] ?? false,
      maxSessionsPerLearner: map['maxSessionsPerLearner'] ?? 10,
      maxSessionsPerTeacher: map['maxSessionsPerTeacher'] ?? 50,
      showLeaderboardToLearners: map['showLeaderboardToLearners'] ?? true,
      enableGamification: map['enableGamification'] ?? true,
      allowTeacherToCreateExams: map['allowTeacherToCreateExams'] ?? true,
      allowLearnerToTakeSelfQuiz: map['allowLearnerToTakeSelfQuiz'] ?? true,
      enableFeedbackOnSessions: map['enableFeedbackOnSessions'] ?? false,
      allowTeachersToShareMaterials: map['allowTeachersToShareMaterials'] ?? true,
      allowLearnersToComment: map['allowLearnersToComment'] ?? false,
      trackSessionAttendance: map['trackSessionAttendance'] ?? true,
      centerPubliclyVisible: map['centerPubliclyVisible'] ?? false,
      allowManualGrading: map['allowManualGrading'] ?? true,
      dailyStudyReminderEnabled: map['dailyStudyReminderEnabled'] ?? false,
      showInstructorNamesToLearners: map['showInstructorNamesToLearners'] ?? true,
      centerLanguage: map['centerLanguage'] ?? 'en',
      allowMultipleRolesPerUser: map['allowMultipleRolesPerUser'] ?? false,
      allowStudentToInvite: map['allowStudentToInvite'] ?? false,
      sessionSorting: map['sessionSorting'] ?? 'recent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'learnerCanCreateSession': learnerCanCreateSession,
      'teacherCanCreateSession': teacherCanCreateSession,
      'shareSessionsWithTeachers': shareSessionsWithTeachers,
      'shareSessionsWithLearners': shareSessionsWithLearners,
      'learnerCanAccessExamPage': learnerCanAccessExamPage,
      'teacherCanAccessExamPage': teacherCanAccessExamPage,
      'enableJoinRequests': enableJoinRequests,
      'autoApproveLearners': autoApproveLearners,
      'autoApproveInstructors': autoApproveInstructors,
      'allowLearnerStoryBuilder': allowLearnerStoryBuilder,
      'allowTeacherToManageLearners': allowTeacherToManageLearners,
      'examVisibleToLearnersAfterSessionDone': examVisibleToLearnersAfterSessionDone,
      'sessionApprovalRequiredForTeachers': sessionApprovalRequiredForTeachers,
      'maxSessionsPerLearner': maxSessionsPerLearner,
      'maxSessionsPerTeacher': maxSessionsPerTeacher,
      'showLeaderboardToLearners': showLeaderboardToLearners,
      'enableGamification': enableGamification,
      'allowTeacherToCreateExams': allowTeacherToCreateExams,
      'allowLearnerToTakeSelfQuiz': allowLearnerToTakeSelfQuiz,
      'enableFeedbackOnSessions': enableFeedbackOnSessions,
      'allowTeachersToShareMaterials': allowTeachersToShareMaterials,
      'allowLearnersToComment': allowLearnersToComment,
      'trackSessionAttendance': trackSessionAttendance,
      'centerPubliclyVisible': centerPubliclyVisible,
      'allowManualGrading': allowManualGrading,
      'dailyStudyReminderEnabled': dailyStudyReminderEnabled,
      'showInstructorNamesToLearners': showInstructorNamesToLearners,
      'centerLanguage': centerLanguage,
      'allowMultipleRolesPerUser': allowMultipleRolesPerUser,
      'allowStudentToInvite': allowStudentToInvite,
      'sessionSorting': sessionSorting,
    };
  }

  CenterConfig copyWith({
    bool? learnerCanCreateSession,
    bool? teacherCanCreateSession,
    bool? shareSessionsWithTeachers,
    bool? shareSessionsWithLearners,
    bool? learnerCanAccessExamPage,
    bool? teacherCanAccessExamPage,
    bool? enableJoinRequests,
    bool? autoApproveLearners,
    bool? autoApproveInstructors,
    bool? allowLearnerStoryBuilder,
    bool? allowTeacherToManageLearners,
    bool? examVisibleToLearnersAfterSessionDone,
    bool? sessionApprovalRequiredForTeachers,
    int? maxSessionsPerLearner,
    int? maxSessionsPerTeacher,
    bool? showLeaderboardToLearners,
    bool? enableGamification,
    bool? allowTeacherToCreateExams,
    bool? allowLearnerToTakeSelfQuiz,
    bool? enableFeedbackOnSessions,
    bool? allowTeachersToShareMaterials,
    bool? allowLearnersToComment,
    bool? trackSessionAttendance,
    bool? centerPubliclyVisible,
    bool? allowManualGrading,
    bool? dailyStudyReminderEnabled,
    bool? showInstructorNamesToLearners,
    String? centerLanguage,
    bool? allowMultipleRolesPerUser,
    bool? allowStudentToInvite,
    String? sessionSorting,
  }) {
    return CenterConfig(
      learnerCanCreateSession: learnerCanCreateSession ?? this.learnerCanCreateSession,
      teacherCanCreateSession: teacherCanCreateSession ?? this.teacherCanCreateSession,
      shareSessionsWithTeachers: shareSessionsWithTeachers ?? this.shareSessionsWithTeachers,
      shareSessionsWithLearners: shareSessionsWithLearners ?? this.shareSessionsWithLearners,
      learnerCanAccessExamPage: learnerCanAccessExamPage ?? this.learnerCanAccessExamPage,
      teacherCanAccessExamPage: teacherCanAccessExamPage ?? this.teacherCanAccessExamPage,
      enableJoinRequests: enableJoinRequests ?? this.enableJoinRequests,
      autoApproveLearners: autoApproveLearners ?? this.autoApproveLearners,
      autoApproveInstructors: autoApproveInstructors ?? this.autoApproveInstructors,
      allowLearnerStoryBuilder: allowLearnerStoryBuilder ?? this.allowLearnerStoryBuilder,
      allowTeacherToManageLearners: allowTeacherToManageLearners ?? this.allowTeacherToManageLearners,
      examVisibleToLearnersAfterSessionDone:
          examVisibleToLearnersAfterSessionDone ?? this.examVisibleToLearnersAfterSessionDone,
      sessionApprovalRequiredForTeachers: sessionApprovalRequiredForTeachers ?? this.sessionApprovalRequiredForTeachers,
      maxSessionsPerLearner: maxSessionsPerLearner ?? this.maxSessionsPerLearner,
      maxSessionsPerTeacher: maxSessionsPerTeacher ?? this.maxSessionsPerTeacher,
      showLeaderboardToLearners: showLeaderboardToLearners ?? this.showLeaderboardToLearners,
      enableGamification: enableGamification ?? this.enableGamification,
      allowTeacherToCreateExams: allowTeacherToCreateExams ?? this.allowTeacherToCreateExams,
      allowLearnerToTakeSelfQuiz: allowLearnerToTakeSelfQuiz ?? this.allowLearnerToTakeSelfQuiz,
      enableFeedbackOnSessions: enableFeedbackOnSessions ?? this.enableFeedbackOnSessions,
      allowTeachersToShareMaterials: allowTeachersToShareMaterials ?? this.allowTeachersToShareMaterials,
      allowLearnersToComment: allowLearnersToComment ?? this.allowLearnersToComment,
      trackSessionAttendance: trackSessionAttendance ?? this.trackSessionAttendance,
      centerPubliclyVisible: centerPubliclyVisible ?? this.centerPubliclyVisible,
      allowManualGrading: allowManualGrading ?? this.allowManualGrading,
      dailyStudyReminderEnabled: dailyStudyReminderEnabled ?? this.dailyStudyReminderEnabled,
      showInstructorNamesToLearners: showInstructorNamesToLearners ?? this.showInstructorNamesToLearners,
      centerLanguage: centerLanguage ?? this.centerLanguage,
      allowMultipleRolesPerUser: allowMultipleRolesPerUser ?? this.allowMultipleRolesPerUser,
      allowStudentToInvite: allowStudentToInvite ?? this.allowStudentToInvite,
      sessionSorting: sessionSorting ?? this.sessionSorting,
    );
  }
}
