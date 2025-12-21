//
//  S3Service.swift
//  ASCookBook
//
//  Created for AWS S3 integration
//

import Foundation
import AWSS3
import AWSSDKIdentity
import SmithyIdentity
import Smithy
import ClientRuntime
import AWSClientRuntime

class S3Service {
    private let bucketName: String
    private let region: String
    private let s3Client: S3Client
    
    init(bucketName: String, region: String = "us-east-1") async throws {
        self.bucketName = bucketName
        self.region = region
        
        // Configure AWS credentials
        // The SDK will automatically look for credentials in:
        // 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
        // 2. ~/.aws/credentials file
        // 3. IAM role (if running on EC2)
        // For explicit credentials, use StaticAWSCredentialIdentityResolver:
        let credentials = AWSCredentialIdentity(
            accessKey: Constants.awsAccessKeyId,
            secret: Constants.awsSecretAccessKey
        )
            
        let identityResolver = StaticAWSCredentialIdentityResolver(credentials)
        
        let config = try await S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: identityResolver,
            region: region
        )
        
        self.s3Client = S3Client(config: config)
    }
    
    /// Uploads image data to S3 and returns the object key
    func uploadImage(_ imageData: Data, key: String, contentType: String = "image/jpeg") async throws -> String {
        let input = PutObjectInput(
            body: .data(imageData),
            bucket: bucketName,
            contentType: contentType,
            key: key
        )
        
        _ = try await s3Client.putObject(input: input)
        return key
    }
    
    /// Generates a presigned URL for downloading an S3 object
    /// - Parameters:
    ///   - key: The S3 object key
    ///   - expirationMinutes: How long the URL should be valid (default: 60 minutes)
    /// - Returns: A presigned URL string
    func getPresignedURL(for key: String, expirationMinutes: Int = 60) async throws -> String {
        let getInput = GetObjectInput(
            bucket: bucketName,
            key: key
        )
        
        let presignedRequest = try await s3Client.presignedRequestForGetObject(
            input: getInput,
            expiration: TimeInterval(expirationMinutes * 60)
        )
        
        guard let url = presignedRequest.url else {
            throw NSError(domain: "S3Service", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate presigned URL"])
        }
        
        return url.absoluteString
    }
    
    /// Generates a presigned URL for uploading (PUT request)
    /// - Parameters:
    ///   - key: The S3 object key
    ///   - contentType: The content type of the file
    ///   - expirationMinutes: How long the URL should be valid (default: 60 minutes)
    /// - Returns: A presigned URL string for uploading
    func getPresignedUploadURL(for key: String, contentType: String = "image/jpeg", expirationMinutes: Int = 60) async throws -> String {
        let credentials = AWSCredentialIdentity(
            accessKey: Constants.awsAccessKeyId,
            secret: Constants.awsSecretAccessKey
        )
        
        let identityResolver = StaticAWSCredentialIdentityResolver(credentials)
        
        let config = try await S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: identityResolver,
            region: region
        )
        
        let putInput = PutObjectInput(
            bucket: bucketName,
            contentType: contentType, key: key
        )
        
        let presignedURL = try await putInput.presignURL(
            config: config,
            expiration: TimeInterval(expirationMinutes * 60)
        )
        
        guard let url = presignedURL else {
            throw NSError(domain: "S3Service", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate presigned upload URL"])
        }
        
        return url.absoluteString
    }
    
    /// Deletes an object from S3
    func deleteImage(key: String) async throws {
        let input = DeleteObjectInput(
            bucket: bucketName,
            key: key
        )
        
        _ = try await s3Client.deleteObject(input: input)
    }
    
    /// Generates a unique key for an image based on recipe ID and timestamp
    static func generateImageKey(recipeId: String? = nil, fileExtension: String = "jpg") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        if let recipeId = recipeId {
            return "recipes/\(recipeId)/\(timestamp)-\(uuid).\(fileExtension)"
        } else {
            return "recipes/\(timestamp)-\(uuid).\(fileExtension)"
        }
    }
}

