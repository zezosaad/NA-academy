import {
  Injectable,
  ConflictException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument, UserRole, UserStatus } from './schemas/user.schema.js';
import { ListUsersQueryDto } from './dto/list-users-query.dto.js';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly SALT_ROUNDS = 12;

  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
  ) {}

  async create(data: {
    email: string;
    password: string;
    name: string;
    role?: UserRole;
  }): Promise<UserDocument> {
    const existing = await this.userModel.findOne({ email: data.email.toLowerCase() }).exec();
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(data.password, this.SALT_ROUNDS);

    const user = new this.userModel({
      email: data.email.toLowerCase(),
      passwordHash,
      name: data.name,
      role: data.role || UserRole.STUDENT,
      status: UserStatus.ACTIVE,
    });

    return user.save();
  }

  async createUser(dto: any): Promise<UserDocument> {
    const user = new this.userModel(dto);
    return user.save();
  }

  async createAdminUser(dto: any): Promise<UserDocument> {
    const adminDto = { ...dto, role: 'admin' };
    const user = new this.userModel(adminDto);
    return user.save();
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email: email.toLowerCase() }).exec();
  }

  async findById(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).exec();
  }

  async findAll(query: ListUsersQueryDto): Promise<{ data: UserDocument[]; total: number }> {
    const filter: Record<string, any> = {};

    if (query.role) {
      filter.role = query.role;
    }
    if (query.status) {
      filter.status = query.status;
    }
    if (query.search) {
      filter.$or = [
        { name: { $regex: query.search, $options: 'i' } },
        { email: { $regex: query.search, $options: 'i' } },
      ];
    }

    const skip = (query.page - 1) * query.limit;

    const [data, total] = await Promise.all([
      this.userModel
        .find(filter)
        .select('-passwordHash')
        .skip(skip)
        .limit(query.limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.userModel.countDocuments(filter).exec(),
    ]);

    return { data, total };
  }

  async updateStatus(id: string, status: UserStatus): Promise<UserDocument> {
    const user = await this.userModel
      .findByIdAndUpdate(id, { status }, { new: true })
      .select('-passwordHash')
      .exec();

    if (!user) {
      throw new NotFoundException('User not found');
    }

    this.logger.log(`User ${id} status updated to ${status}`);
    return user;
  }

  async validatePassword(user: UserDocument, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.passwordHash);
  }
}
