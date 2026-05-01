import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserDocument, UserRole, UserStatus } from '../users/schemas/user.schema.js';
import { Subject, SubjectDocument } from '../subjects/schemas/subject.schema.js';

@Injectable()
export class AudienceResolverService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>,
  ) {}

  /**
   * Resolves all active students.
   */
  async resolveAll(): Promise<Types.ObjectId[]> {
    const users = await this.userModel
      .find({ status: UserStatus.ACTIVE, role: UserRole.STUDENT })
      .select('_id')
      .lean()
      .exec();
    return users.map((u) => u._id);
  }

  /**
   * Stub — to be implemented in US3 (T062).
   */
  async resolveUserList(userIds: string[]): Promise<Types.ObjectId[]> {
    const validIds = userIds.filter((id) => Types.ObjectId.isValid(id));
    const objectIds = validIds.map((id) => new Types.ObjectId(id));

    const users = await this.userModel
      .find({
        _id: { $in: objectIds },
        status: UserStatus.ACTIVE,
      })
      .select('_id')
      .lean()
      .exec();

    if (users.length !== userIds.length) {
      throw new NotFoundException('One or more users were not found or inactive');
    }

    return users.map((user) => user._id);
  }

  /**
   * Stub — to be implemented in US3 (T063).
   */

  async resolveSubject(
    subjectId: string,
    currentUserId: string,
    currentUserRole: string,
  ): Promise<Types.ObjectId[]> {
    const subject = await this.subjectModel
      .findById(subjectId)
      .select('_id createdBy')
      .lean()
      .exec();
    if (!subject) {
      throw new NotFoundException('subject-not-found');
    }

    if (
      currentUserRole === UserRole.TEACHER &&
      subject.createdBy?.toString() !== currentUserId.toString()
    ) {
      throw new ForbiddenException('audience-forbidden');
    }

    const users = await this.userModel
      .find({
        status: UserStatus.ACTIVE,
        role: UserRole.STUDENT,
        assignedSubjects: new Types.ObjectId(subjectId),
      })
      .select('_id')
      .lean()
      .exec();

    return users.map((user) => user._id);
  }
}
