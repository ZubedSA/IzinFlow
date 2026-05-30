import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterOrgDto } from './dto/register-org.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    login(dto: LoginDto): Promise<{
        accessToken: string;
        user: {
            id: string;
            email: string;
            fullName: string;
            role: import(".prisma/client").$Enums.UserRole;
            avatarUrl: string;
        };
        organization: {
            id: string;
            name: string;
            slug: string;
            logoUrl: string;
            brandColor: string;
        };
    }>;
    registerOrg(dto: RegisterOrgDto): Promise<{
        message: string;
        organizationId: string;
        slug: string;
    }>;
    createClassroom(tenantId: string, dto: any): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        name: string;
        homeroomTeacherId: string | null;
    }>;
    getClassrooms(tenantId: string): Promise<({
        homeroomTeacher: {
            user: {
                id: string;
                organizationId: string;
                email: string;
                passwordHash: string;
                role: import(".prisma/client").$Enums.UserRole;
                fullName: string;
                avatarUrl: string | null;
                isActive: boolean;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
            };
        } & {
            id: string;
            organizationId: string;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            userId: string;
            employeeNumber: string | null;
        };
    } & {
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        name: string;
        homeroomTeacherId: string | null;
    })[]>;
    createTeacher(tenantId: string, dto: any): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        employeeNumber: string | null;
    }>;
    getTeachers(tenantId: string): Promise<({
        user: {
            id: string;
            organizationId: string;
            email: string;
            passwordHash: string;
            role: import(".prisma/client").$Enums.UserRole;
            fullName: string;
            avatarUrl: string | null;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
        };
    } & {
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        employeeNumber: string | null;
    })[]>;
    createStudent(tenantId: string, dto: any): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        studentIdNumber: string | null;
        classRoomId: string;
        parentId: string | null;
    }>;
    getStudents(tenantId: string): Promise<({
        user: {
            id: string;
            organizationId: string;
            email: string;
            passwordHash: string;
            role: import(".prisma/client").$Enums.UserRole;
            fullName: string;
            avatarUrl: string | null;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
        };
        classRoom: {
            id: string;
            organizationId: string;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            name: string;
            homeroomTeacherId: string | null;
        };
    } & {
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        studentIdNumber: string | null;
        classRoomId: string;
        parentId: string | null;
    })[]>;
    updateClassroom(tenantId: string, id: string, dto: any): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        name: string;
        homeroomTeacherId: string | null;
    }>;
    deleteClassroom(tenantId: string, id: string): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        name: string;
        homeroomTeacherId: string | null;
    }>;
    updateTeacher(tenantId: string, id: string, dto: any): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        employeeNumber: string | null;
    }>;
    deleteTeacher(tenantId: string, id: string): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        employeeNumber: string | null;
    }>;
    updateStudent(tenantId: string, id: string, dto: any): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        studentIdNumber: string | null;
        classRoomId: string;
        parentId: string | null;
    }>;
    deleteStudent(tenantId: string, id: string): Promise<{
        id: string;
        organizationId: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        studentIdNumber: string | null;
        classRoomId: string;
        parentId: string | null;
    }>;
    deleteOrganization(id: string): Promise<{
        id: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        slug: string;
        logoUrl: string | null;
        brandColor: string;
        address: string | null;
        contact: string | null;
    }>;
}
