//
//  S3Service.swift
//  ASCookBook
//
//  Created for AWS S3 integration
//

import Foundation
import AWSS3
import SmithyIdentity
import Smithy

class S3Service {
  
    func uploadAndGetTemporaryLink(imageData: Data) async throws -> URL {
        let bucketName = Constants.awsS3BucketName
        let region = Constants.awsRegion
        
        let credentials = AWSCredentialIdentity(
            accessKey: Constants.awsAccessKeyId,
            secret: Constants.awsSecretAccessKey)
        
        let identityResolver = StaticAWSCredentialIdentityResolver(credentials)
        
        let config = try await S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: identityResolver,
            region: region
        )
        
        let s3Client = S3Client(config: config)
        
        let input = PutObjectInput(
            body: .data(imageData),
            bucket: bucketName,
            contentType: "image/jpeg",
            key: "recipe.jpg")
        
        _ = try await s3Client.putObject(input: input)
        
        let getInput = GetObjectInput(
            bucket: bucketName,
            key: "recipe.jpg"
        )
        
        // Generate presigned URL using the same config
        let presignedURL = try await getInput.presignURL(
            config: config,
            expiration: TimeInterval(300)
        )
        
        guard let url = presignedURL else {
            throw NSError(domain: "S3Service", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate presigned URL"])
        }

        return url
    }
}

