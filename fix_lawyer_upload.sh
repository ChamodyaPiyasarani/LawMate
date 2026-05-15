sed -i '' 's/let fileName = url.lastPathComponent/let originalName = url.lastPathComponent\n                let safeStorageName = UUID().uuidString + "." + url.pathExtension\n                let fileName = safeStorageName/' LawMate/Views/Lawyer/LawyerCaseDetailView.swift
sed -i '' 's/let path = "cases\\/\\(legalCase.id ?? "unknown"\\)"/let path = "cases\\/\\(legalCase.id ?? "unknown"\\)\\/docs"/' LawMate/Views/Lawyer/LawyerCaseDetailView.swift
sed -i '' 's/fileName: fileName,/fileName: originalName,/' LawMate/Views/Lawyer/LawyerCaseDetailView.swift
