import { Injectable, NotImplementedException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserDocument, UserRole, UserStatus } from '../users/schemas/user.schema.js';

@Injectable()
export class AudienceResolverService {
  constructor(@InjectModel(User.name) private readonly userModel: Model<UserDocument>) {}

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
  resolveUserList(_userIds: string[]): Promise<Types.ObjectId[]> {
    void _userIds;
    throw new NotImplementedException('resolveUserList is not yet implemented');
  }

  /**
   * Stub — to be implemented in US3 (T063).
   */

  resolveSubject(
    _subjectId: string,
    _currentUserId: string,
    _currentUserRole: string,
  ): Promise<Types.ObjectId[]> {
    void _subjectId;
    void _currentUserId;
    void _currentUserRole;
    throw new NotImplementedException('resolveSubject is not yet implemented');
  }
}
