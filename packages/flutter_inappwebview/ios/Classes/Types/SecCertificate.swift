//
//  SecCertificate.swift
//  flutter_inappwebview
//
//  Created by Lorenzo Pichilli on 19/02/21.
//

import Foundation

extension SecCertificate {
    var data: Data {
        let serverCertificateCFData = SecCertificateCopyData(self)
        let data = CFDataGetBytePtr(serverCertificateCFData)
        let size = CFDataGetLength(serverCertificateCFData)
        let certificateData = NSData(bytes: data, length: size)
        return Data(certificateData)
    }
}
