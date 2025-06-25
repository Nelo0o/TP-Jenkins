

const UserCard = ({ user }: { user: User }) => {
    return (
        <div className="user-card">
            <h2 className="user-card__name">{user.name}</h2>
            <p className="user-card__email">{user.email}</p>
        </div>
    );
};

export default UserCard;
